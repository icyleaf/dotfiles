#!/usr/bin/env python3
"""
Manga backend server for local.manga.
Scrapes WeebCentral and serves clean JSON on http://127.0.0.1:5150

Endpoints:
  GET /search?q=<query>&type=<Manga|Manhwa|Manhua>&offset=<n>
  GET /info?id=<series_id>        (id = "SERIESID/Slug-Name")
  GET /pages?chapterId=<id>
  GET /image?url=<encoded_url>    (image proxy — bypasses CDN UA checks)
  GET /hot
  GET /latest?page=<n>
  GET /health
"""

import os
import re
import json
import time
import shutil
import logging
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from logging.handlers import RotatingFileHandler
from socketserver import ThreadingMixIn
from urllib.parse import urlparse, parse_qs, quote, unquote
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor

PORT        = 5150
BASE        = "https://weebcentral.com"
COVER_SMALL = "https://temp.compsci88.com/cover/small"
COVER_BASE  = "https://temp.compsci88.com/cover/fallback"
PAGE_LIMIT  = 32
BACKEND_VERSION = "2026-07-09.2"

# ── Persistent storage + logging ───────────────────────────────────────────
DATA_DIR       = os.path.expanduser("~/.local/share/omarchy-manga")
FAVORITES_FILE = os.path.join(DATA_DIR, "favorites.json")
DOWNLOADS_DIR  = os.path.join(DATA_DIR, "downloads")
LOG_FILE       = os.path.join(DATA_DIR, "manga_server.log")
os.makedirs(DATA_DIR,      exist_ok=True)
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

logger = logging.getLogger("manga-server")
logger.setLevel(logging.INFO)
logger.propagate = False

if not logger.handlers:
    formatter = logging.Formatter(
        "%(asctime)s %(levelname)s [%(threadName)s] %(message)s",
        "%Y-%m-%d %H:%M:%S",
    )
    file_handler = RotatingFileHandler(
        LOG_FILE,
        maxBytes=1024 * 1024,
        backupCount=3,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

logger.info("starting manga backend pid=%s data_dir=%s log_file=%s", os.getpid(), DATA_DIR, LOG_FILE)

# ── Use curl_cffi for browser-grade TLS fingerprinting (bypasses Cloudflare)
# Install: pip install curl_cffi --user
try:
    from curl_cffi.requests import Session as CffiSession
    _session = CffiSession(impersonate="firefox")
    _USE_CFFI = True
    logger.info("using curl_cffi with Firefox impersonation")
except ImportError:
    import requests as _requests_mod
    _session = _requests_mod.Session()
    _USE_CFFI = False
    logger.warning("curl_cffi not found; falling back to requests, which may timeout on Cloudflare")

try:
    import requests as _fallback_requests
    _fallback_session = _fallback_requests.Session()
except ImportError:
    _fallback_requests = None
    _fallback_session = None

HEADERS = {
    "User-Agent":                "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "Accept":                    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language":           "en-US,en;q=0.5",
    "Accept-Encoding":           "gzip, deflate, br",
    "Connection":                "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest":            "document",
    "Sec-Fetch-Mode":            "navigate",
    "Sec-Fetch-Site":            "none",
    "Sec-Fetch-User":            "?1",
    "DNT":                       "1",
}
SEARCH_HEADERS = {
    **HEADERS,
    "HX-Request":        "true",
    "HX-Target":         "search-results",
    "Sec-Fetch-Dest":    "empty",
    "Sec-Fetch-Mode":    "cors",
    "Sec-Fetch-Site":    "same-origin",
    "X-Requested-With":  "XMLHttpRequest",
}

if not _USE_CFFI:
    _session.headers.update(HEADERS)


# ── TTL Cache ──────────────────────────────────────────────────────────────

_cache      = {}
_cache_lock = threading.Lock()

TTL_HOT    = 300
TTL_LATEST = 120
TTL_SEARCH = 600
TTL_INFO   = 1800
TTL_PAGES  = 3600


def _cached(key, ttl, fn):
    with _cache_lock:
        entry = _cache.get(key)
    if entry:
        val, expires = entry
        if time.monotonic() < expires:
            logger.info("cache hit key=%s", key)
            return val
    logger.info("cache miss key=%s ttl=%s", key, ttl)
    val = fn()
    with _cache_lock:
        _cache[key] = (val, time.monotonic() + ttl)
    return val


# ── Helpers ────────────────────────────────────────────────────────────────

def fetch(url, extra_headers=None, timeout=30):
    headers = {**HEADERS, **(extra_headers or {})}
    start = time.monotonic()
    logger.info("fetch start url=%s timeout=%s cffi=%s", url, timeout, _USE_CFFI)
    try:
        if _USE_CFFI:
            r = _session.get(url, headers=headers, timeout=timeout)
        else:
            r = _session.get(url, headers=headers, timeout=timeout)
    except Exception as e:
        if not (_USE_CFFI and _fallback_session):
            raise
        logger.warning("curl_cffi fetch failed, retrying with requests url=%s error=%s", url, e)
        r = _fallback_session.get(url, headers=headers, timeout=timeout)
    r.raise_for_status()
    logger.info(
        "fetch ok status=%s bytes=%s elapsed=%.3fs url=%s",
        getattr(r, "status_code", "?"),
        len(r.text or ""),
        time.monotonic() - start,
        url,
    )
    return r.text


def _raw_get(url, timeout=30):
    """Return raw bytes + content-type for image proxy."""
    start = time.monotonic()
    logger.info("raw image fetch start url=%s timeout=%s cffi=%s", url, timeout, _USE_CFFI)
    try:
        if _USE_CFFI:
            r = _session.get(url, headers=HEADERS, timeout=timeout)
        else:
            r = _session.get(url, headers=HEADERS, timeout=timeout)
    except Exception as e:
        if not (_USE_CFFI and _fallback_session):
            raise
        logger.warning("curl_cffi image fetch failed, retrying with requests url=%s error=%s", url, e)
        r = _fallback_session.get(url, headers=HEADERS, timeout=timeout)
    r.raise_for_status()
    logger.info(
        "raw image fetch ok status=%s bytes=%s elapsed=%.3fs url=%s",
        getattr(r, "status_code", "?"),
        len(r.content or b""),
        time.monotonic() - start,
        url,
    )
    return r.content, r.headers.get("Content-Type", "image/jpeg")


def series_id(full_id):
    return full_id.split("/")[0]


def clean_text(html):
    return re.sub(r"<[^>]+>", "", html).strip()


def proxy_url(img_url):
    return f"http://127.0.0.1:{PORT}/image?url={quote(img_url, safe='')}"


def cover_url(sid):
    return proxy_url(f"{COVER_SMALL}/{sid}.webp")


def existing_server_healthy(timeout=1.0):
    url = f"http://127.0.0.1:{PORT}/health"
    try:
        with urlopen(url, timeout=timeout) as response:
            body = response.read(1024)
            try:
                payload = json.loads(body.decode("utf-8"))
            except Exception:
                payload = {}
            healthy = (
                response.status == 200
                and payload.get("ok") is True
                and payload.get("version") == BACKEND_VERSION
            )
            logger.info(
                "existing backend probe status=%s healthy=%s expected_version=%s body=%r",
                response.status,
                healthy,
                BACKEND_VERSION,
                body[:120],
            )
            return healthy
    except Exception as e:
        logger.info("existing backend probe failed url=%s error=%s", url, e)
        return False


# ── Search ─────────────────────────────────────────────────────────────────

def search(query, mtype=None, offset=0, sort="Latest Updates"):
    key = f"search:{query}:{mtype}:{offset}:{sort}"
    return _cached(key, TTL_SEARCH, lambda: _search(query, mtype, offset, sort))


def _search(query, mtype, offset, sort):
    logger.info("search query=%r type=%r offset=%s sort=%r", query, mtype, offset, sort)
    params = (
        f"text={quote(query)}"
        f"&limit={PAGE_LIMIT}"
        f"&offset={offset}"
        f"&official=Any&anime_only=any&display_mode=Minimal+Display"
        f"&sort={quote(sort)}"
    )
    if mtype:
        params += f"&included_type={quote(mtype)}"

    html     = fetch(f"{BASE}/search/data?{params}", extra_headers=SEARCH_HEADERS)
    articles = re.findall(r"<article[^>]*>(.*?)</article>", html, re.S)
    logger.info("search html articles=%s query=%r", len(articles), query)

    results = []
    for a in articles:
        href  = re.search(r'href="https://weebcentral\.com/series/([^"]+)"', a)
        title = re.search(r"<h2[^>]*>([^<]+)</h2>", a)
        if not (href and title):
            continue
        sid  = href.group(1)
        bid  = series_id(sid)
        divs = re.findall(r"<div>([^<]+)</div>", a)
        tags = re.findall(r"<span>([^<,]+),?</span>", a)
        results.append({
            "id":     sid,
            "title":  clean_text(title.group(1)),
            "image":  cover_url(bid),
            "status": divs[2].strip() if len(divs) >= 3 else "",
            "year":   divs[1].strip() if len(divs) >= 2 else "",
            "type":   divs[0].strip() if len(divs) >= 1 else "",
            "tags":   [t.strip() for t in tags if t.strip()],
        })

    logger.info("search parsed results=%s hasMore=%s nextOffset=%s query=%r", len(results), len(results) >= PAGE_LIMIT, offset + len(results), query)
    return {
        "results":    results,
        "hasMore":    len(results) >= PAGE_LIMIT,
        "nextOffset": offset + len(results),
    }


# ── Info + Chapters ─────────────────────────────────────────────────────────

def info(full_id):
    return _cached(f"info:{full_id}", TTL_INFO, lambda: _info(full_id))


def _info(full_id):
    logger.info("info start id=%s", full_id)
    bid = series_id(full_id)

    with ThreadPoolExecutor(max_workers=2) as ex:
        f_detail = ex.submit(fetch, f"{BASE}/series/{full_id}")
        f_chaps  = ex.submit(fetch, f"{BASE}/series/{bid}/full-chapter-list")
        detail_html = f_detail.result()
        ch_html     = f_chaps.result()

    title_m  = re.search(r"<title>([^|<]+)", detail_html)
    status_m = re.search(r"Status: </strong>.*?<a[^>]+>([^<]+)</a>", detail_html, re.S)
    og_img   = re.search(r'og:image" content="([^"]+)"', detail_html)

    authors = []
    for block in re.findall(r'(?:Authors?|Artists?): </strong>(.*?)(?:</li>|</ul>)', detail_html, re.S):
        for name in re.findall(r"<a[^>]+>([^<]+)</a>", block):
            n = name.strip()
            if n and n not in authors:
                authors.append(n)

    description = ""
    for p in re.findall(r"<p[^>]*>([\s\S]{80,600}?)</p>", detail_html):
        c = clean_text(p)
        if c and "{" not in c and "function" not in c and "Login" not in c:
            description = c
            break

    anchors = re.findall(
        r'<a\s+href="https://weebcentral\.com/chapters/([^"]+)"[^>]*>([\s\S]*?)</a>',
        ch_html, re.S
    )
    chapters = []
    for cid, inner in anchors:
        spans      = re.findall(r"<span[^>]*>([\s\S]*?)</span>", inner)
        text_spans = [clean_text(s) for s in spans if clean_text(s) and "{" not in s and len(clean_text(s)) > 1]
        ch_label   = text_spans[0] if text_spans else ""
        ch_num     = re.sub(r"(?i)chapter\s*", "", ch_label).strip()
        dt_m       = re.search(r'datetime="([^"]+)"', inner)
        chapters.append({
            "id":        cid,
            "title":     ch_label,
            "chapter":   ch_num,
            "publishAt": dt_m.group(1) if dt_m else "",
        })
    chapters.reverse()

    raw_cover = og_img.group(1) if og_img else f"{COVER_BASE}/{bid}.jpg"
    logger.info("info parsed id=%s title=%r chapters=%s authors=%s", full_id, clean_text(title_m.group(1)).strip() if title_m else "", len(chapters), len(authors))
    return {
        "id":          full_id,
        "title":       clean_text(title_m.group(1)).strip() if title_m else "",
        "description": description,
        "status":      status_m.group(1).strip() if status_m else "",
        "image":       proxy_url(raw_cover),
        "authors":     authors,
        "chapters":    chapters,
    }


# ── Latest Updates ─────────────────────────────────────────────────────────

def latest_updates(page=1):
    return _cached(f"latest:{page}", TTL_LATEST, lambda: _latest_updates(page))


def _latest_updates(page):
    logger.info("latest start page=%s", page)
    html     = fetch(f"{BASE}/latest-updates/{page}")
    articles = re.findall(r"<article([^>]*)>([\s\S]*?)</article>", html, re.S)
    results  = []
    logger.info("latest html articles=%s page=%s", len(articles), page)

    for attrs, body in articles:
        title_m = re.search(r'data-tip="([^"]+)"', attrs)
        series  = re.search(r'href="https://weebcentral\.com/series/([A-Z0-9]+)/([^"]+)"', body)
        cover   = re.search(r'<img src="(https://temp\.compsci88\.com/[^"]+)"', body)
        ch_num  = re.search(r"Chapter ([0-9][^<]*)<", body)
        dt      = re.search(r'datetime="([^"]+)"', body)

        if not (series and title_m):
            continue

        sid = series.group(1)
        results.append({
            "id":        f"{sid}/{series.group(2)}",
            "title":     title_m.group(1),
            "image":     proxy_url(cover.group(1)) if cover else cover_url(sid),
            "status":    "",
            "type":      "",
            "chapter":   ch_num.group(1).strip() if ch_num else "",
            "updatedAt": dt.group(1) if dt else "",
        })

    has_more = bool(re.search(
        rf'hx-get="https://weebcentral\.com/latest-updates/{page + 1}"', html
    ))

    logger.info("latest parsed results=%s hasMore=%s nextPage=%s", len(results), has_more, page + 1)
    return {
        "results":  results,
        "hasMore":  has_more,
        "nextPage": page + 1,
    }


# ── Hot Updates ────────────────────────────────────────────────────────────

def hot_updates():
    return _cached("hot", TTL_HOT, _hot_updates)


def _hot_updates():
    logger.info("hot start")
    html     = fetch(f"{BASE}/hot-updates")
    articles = re.findall(r"<article[^>]*>([\s\S]*?)</article>", html, re.S)
    results  = []
    seen     = set()
    logger.info("hot html articles=%s", len(articles))

    for a in articles:
        series  = re.search(r'href="https://weebcentral\.com/series/([A-Z0-9]+)/([^"]+)"', a)
        chapter = re.search(r'href="https://weebcentral\.com/chapters/([A-Z0-9]+)"', a)
        cover   = re.search(r'<img src="(https://temp\.compsci88\.com/[^"]+)"', a)
        title   = re.search(r'alt="([^"]+) cover"', a)
        ch_num  = re.search(r"Chapter ([0-9][^<]*)</", a)
        dt      = re.search(r'datetime="([^"]+)"', a)

        if not (series and chapter and title):
            continue
        sid = series.group(1)
        if sid in seen:
            continue
        seen.add(sid)

        results.append({
            "id":        f"{sid}/{series.group(2)}",
            "title":     title.group(1),
            "image":     proxy_url(cover.group(1)) if cover else cover_url(sid),
            "status":    "",
            "type":      "",
            "chapter":   ch_num.group(1) if ch_num else "",
            "updatedAt": dt.group(1) if dt else "",
        })

    logger.info("hot parsed results=%s", len(results))
    return results


# ── Pages ──────────────────────────────────────────────────────────────────

def pages(chapter_id):
    return _cached(f"pages:{chapter_id}", TTL_PAGES, lambda: _pages(chapter_id))


def _pages(chapter_id):
    url  = f"{BASE}/chapters/{chapter_id}/images?is_prev=False&current_page=1&reading_style=long_strip"
    html = fetch(url)

    imgs = re.findall(r'<img[^>]+class="[^"]*maw-w-full[^"]*"[^>]+src="([^"]+)"', html)
    if not imgs:
        imgs = re.findall(r'<img[^>]+src="(https://[^"]+\.(?:jpg|jpeg|png|webp)[^"]*?)"', html, re.I)
        imgs = [i for i in imgs if "weebcentral.com" not in i and "logo" not in i.lower()]

    return [{"page": i + 1, "img": proxy_url(img)} for i, img in enumerate(imgs)]


# ── Favorites ──────────────────────────────────────────────────────────────

_fav_lock = threading.Lock()


def _load_favs():
    with _fav_lock:
        if not os.path.exists(FAVORITES_FILE):
            return []
        with open(FAVORITES_FILE) as f:
            return json.load(f)


def _save_favs(favs):
    with _fav_lock:
        with open(FAVORITES_FILE, "w") as f:
            json.dump(favs, f, indent=2)


def fav_list():
    favs = _load_favs()
    return [{**f, "image": proxy_url(f["image"])} for f in favs]


def fav_add(manga_id, title, raw_image_url):
    favs = _load_favs()
    if any(f["id"] == manga_id for f in favs):
        return {"ok": True}
    favs.append({
        "id":                    manga_id,
        "title":                 title,
        "image":                 raw_image_url,
        "addedAt":               datetime.now(timezone.utc).isoformat(),
        "lastKnownChapterCount": 0,
        "latestSeenChapterId":   "",
        "hasNewChapters":        False,
    })
    _save_favs(favs)
    return {"ok": True}


def fav_remove(manga_id):
    favs = _load_favs()
    _save_favs([f for f in favs if f["id"] != manga_id])
    return {"ok": True}


def fav_mark_seen(manga_id, chapter_id):
    favs = _load_favs()
    for f in favs:
        if f["id"] == manga_id:
            f["latestSeenChapterId"] = chapter_id
            f["hasNewChapters"]      = False
    _save_favs(favs)
    return {"ok": True}


def fav_check():
    favs    = _load_favs()
    updated = []

    def _check_one(fav):
        key = f"info:{fav['id']}"
        with _cache_lock:
            _cache.pop(key, None)
        try:
            data  = info(fav["id"])
            count = len(data.get("chapters", []))
            if count > fav.get("lastKnownChapterCount", 0):
                fav["hasNewChapters"]        = True
                fav["lastKnownChapterCount"] = count
                updated.append({"id": fav["id"], "title": fav["title"], "newCount": count})
            elif not fav.get("hasNewChapters"):
                fav["lastKnownChapterCount"] = count
        except Exception:
            pass

    with ThreadPoolExecutor(max_workers=4) as ex:
        list(ex.map(_check_one, favs))
    _save_favs(favs)
    return {"checked": len(favs), "updated": updated}


# ── Downloads ──────────────────────────────────────────────────────────────

_dl_jobs = {}
_dl_lock = threading.Lock()


def dl_list():
    result = []
    if not os.path.exists(DOWNLOADS_DIR):
        return result
    for sid in sorted(os.listdir(DOWNLOADS_DIR)):
        series_dir  = os.path.join(DOWNLOADS_DIR, sid)
        series_meta = os.path.join(series_dir, "series_meta.json")
        if not os.path.isdir(series_dir) or not os.path.exists(series_meta):
            continue
        with open(series_meta) as f:
            sm = json.load(f)
        chapters = []
        for cid in sorted(os.listdir(series_dir)):
            ch_dir  = os.path.join(series_dir, cid)
            ch_meta = os.path.join(ch_dir, "meta.json")
            if not os.path.isdir(ch_dir) or not os.path.exists(ch_meta):
                continue
            with open(ch_meta) as f:
                chapters.append(json.load(f))
        chapters.sort(key=lambda c: float(c.get("chapterNum", "0") or "0"), reverse=True)
        cover_path      = os.path.join(series_dir, "cover.jpg")
        cover_url_local = f"file://{cover_path}" if os.path.exists(cover_path) else proxy_url(sm.get("rawCoverUrl", ""))
        result.append({**sm, "image": cover_url_local, "chapters": chapters})
    return result


def dl_progress(chapter_id):
    with _dl_lock:
        return _dl_jobs.get(chapter_id, {"status": "not_started"})


def dl_start(manga_id, chapter_id, chapter_num, chapter_title, manga_title, raw_cover_url):
    with _dl_lock:
        job = _dl_jobs.get(chapter_id, {})
        if job.get("status") in ("downloading", "done"):
            return {"ok": False, "message": job["status"]}
        _dl_jobs[chapter_id] = {"status": "pending", "total": 0, "done": 0, "error": None}
    threading.Thread(
        target=_dl_worker,
        args=(manga_id, chapter_id, chapter_num, chapter_title, manga_title, raw_cover_url),
        daemon=True
    ).start()
    return {"ok": True}


def _dl_worker(manga_id, chapter_id, chapter_num, chapter_title, manga_title, raw_cover_url):
    sid    = manga_id.split("/")[0]
    ch_dir = os.path.join(DOWNLOADS_DIR, sid, chapter_id)
    os.makedirs(ch_dir, exist_ok=True)

    try:
        page_list = _pages(chapter_id)
        total     = len(page_list)
        with _dl_lock:
            _dl_jobs[chapter_id].update({"status": "downloading", "total": total})

        for pg in page_list:
            qs       = parse_qs(urlparse(pg["img"]).query)
            real_url = unquote(qs.get("url", [""])[0])
            if not real_url:
                continue
            ext   = real_url.split("?")[0].rsplit(".", 1)[-1].lower()
            ext   = ext if ext in ("jpg", "jpeg", "png", "webp") else "jpg"
            fname = os.path.join(ch_dir, f"{pg['page']:03d}.{ext}")
            if not os.path.exists(fname):
                cached = _img_get(real_url)
                if cached:
                    body = cached[0]
                else:
                    body, ctype = _raw_get(real_url)
                    _img_put(real_url, body, ctype)
                with open(fname, "wb") as f:
                    f.write(body)
            with _dl_lock:
                _dl_jobs[chapter_id]["done"] += 1

        with open(os.path.join(ch_dir, "meta.json"), "w") as f:
            json.dump({
                "chapterId":    chapter_id,
                "chapterNum":   chapter_num,
                "title":        chapter_title,
                "mangaId":      manga_id,
                "mangaTitle":   manga_title,
                "pages":        total,
                "downloadedAt": datetime.now(timezone.utc).isoformat(),
            }, f)

        series_dir  = os.path.join(DOWNLOADS_DIR, sid)
        series_meta = os.path.join(series_dir, "series_meta.json")
        with open(series_meta, "w") as f:
            json.dump({"id": manga_id, "title": manga_title,
                       "localId": sid, "rawCoverUrl": raw_cover_url}, f)

        cover_path = os.path.join(series_dir, "cover.jpg")
        if not os.path.exists(cover_path) and raw_cover_url:
            try:
                body, _ = _raw_get(raw_cover_url, timeout=15)
                with open(cover_path, "wb") as f:
                    f.write(body)
            except Exception:
                pass

        with _dl_lock:
            _dl_jobs[chapter_id]["status"] = "done"

    except Exception as e:
        import traceback; traceback.print_exc()
        with _dl_lock:
            _dl_jobs[chapter_id] = {"status": "error", "total": 0, "done": 0, "error": str(e)}


def dl_pages(chapter_id):
    for sid in os.listdir(DOWNLOADS_DIR):
        ch_dir = os.path.join(DOWNLOADS_DIR, sid, chapter_id)
        if os.path.isdir(ch_dir):
            files = sorted(f for f in os.listdir(ch_dir)
                           if f[0].isdigit() and f.rsplit(".", 1)[-1].lower()
                           in ("jpg", "jpeg", "png", "webp"))
            return [{"page": i + 1, "img": f"file://{os.path.join(ch_dir, fn)}"}
                    for i, fn in enumerate(files)]
    return []


def dl_remove(chapter_id):
    for sid in os.listdir(DOWNLOADS_DIR):
        ch_dir = os.path.join(DOWNLOADS_DIR, sid, chapter_id)
        if os.path.isdir(ch_dir):
            shutil.rmtree(ch_dir)
            series_dir = os.path.join(DOWNLOADS_DIR, sid)
            remaining  = [d for d in os.listdir(series_dir) if os.path.isdir(os.path.join(series_dir, d))]
            if not remaining:
                shutil.rmtree(series_dir)
            with _dl_lock:
                _dl_jobs.pop(chapter_id, None)
            return {"ok": True}
    return {"ok": False, "error": "not found"}


# ── Image byte cache ───────────────────────────────────────────────────────

_img_cache      = {}
_img_cache_lock = threading.Lock()
_img_cache_max  = 600
_img_sem        = threading.Semaphore(10)


def _img_get(url):
    with _img_cache_lock:
        return _img_cache.get(url)


def _img_put(url, body, ctype):
    with _img_cache_lock:
        if len(_img_cache) >= _img_cache_max:
            _img_cache.pop(next(iter(_img_cache)))
        _img_cache[url] = (body, ctype)


def _send_image(handler, body, ctype):
    handler.send_response(200)
    handler.send_header("Content-Type", ctype)
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("Cache-Control", "public, max-age=86400")
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.end_headers()
    try:
        handler.wfile.write(body)
    except (BrokenPipeError, ConnectionResetError):
        pass


# ── Image proxy ─────────────────────────────────────────────────────────────

def proxy_image(handler, img_url):
    cached = _img_get(img_url)
    if cached:
        _send_image(handler, *cached)
        return

    with _img_sem:
        body, ctype = _raw_get(img_url)

    _img_put(img_url, body, ctype)
    _send_image(handler, body, ctype)


# ── HTTP Server ────────────────────────────────────────────────────────────

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads      = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        logger.info("http %s - %s", self.client_address[0], fmt % args)

    def _json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _error(self, msg, status=500):
        logger.warning("response error status=%s path=%s msg=%s", status, getattr(self, "path", ""), msg)
        self._json({"error": msg}, status)

    def do_HEAD(self):
        parsed = urlparse(self.path)
        if parsed.path == "/image":
            self.send_response(200)
            self.send_header("Content-Type", "image/jpeg")
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        qs     = parse_qs(parsed.query)
        start  = time.monotonic()

        def param(key, default=""):
            return (qs.get(key) or [default])[0]

        try:
            p = parsed.path
            logger.info("GET start path=%s query=%s", p, parsed.query)

            if p == "/hot":
                self._json(hot_updates())
            elif p == "/latest":
                self._json(latest_updates(int(param("page", "1"))))
            elif p == "/search":
                q = param("q")
                if not q:
                    return self._error("missing q", 400)
                self._json(search(q, param("type") or None,
                                  int(param("offset", "0")),
                                  param("sort", "Latest Updates")))
            elif p == "/info":
                mid = param("id")
                if not mid:
                    return self._error("missing id", 400)
                self._json(info(mid))
            elif p == "/pages":
                cid = param("chapterId")
                if not cid:
                    return self._error("missing chapterId", 400)
                self._json(pages(cid))
            elif p == "/image":
                img_url = unquote(param("url"))
                if not img_url:
                    return self._error("missing url", 400)
                proxy_image(self, img_url)
            elif p == "/favorites":
                self._json(fav_list())
            elif p == "/favorites/check":
                self._json(fav_check())
            elif p == "/dl/list":
                self._json(dl_list())
            elif p == "/dl/progress":
                cid = param("chapterId")
                if not cid:
                    return self._error("missing chapterId", 400)
                self._json(dl_progress(cid))
            elif p == "/dl/pages":
                cid = param("chapterId")
                if not cid:
                    return self._error("missing chapterId", 400)
                self._json(dl_pages(cid))
            elif p == "/health":
                self._json({
                    "ok": True,
                    "version": BACKEND_VERSION,
                    "pid": os.getpid(),
                    "cffi": _USE_CFFI,
                    "dataDir": DATA_DIR,
                })
            else:
                self._error("not found", 404)
            logger.info("GET done path=%s elapsed=%.3fs", p, time.monotonic() - start)

        except (BrokenPipeError, ConnectionResetError):
            logger.warning("GET client disconnected path=%s", parsed.path)
        except Exception as e:
            logger.exception("GET failed path=%s query=%s", parsed.path, parsed.query)
            self._error(str(e))

    def do_POST(self):
        parsed = urlparse(self.path)
        start  = time.monotonic()
        try:
            length = int(self.headers.get("Content-Length", 0))
            body   = json.loads(self.rfile.read(length)) if length else {}
        except Exception:
            logger.exception("POST bad request body path=%s", parsed.path)
            return self._error("bad request body", 400)

        try:
            p = parsed.path
            safe_body = {k: v for k, v in body.items() if "password" not in k.lower() and "token" not in k.lower()}
            logger.info("POST start path=%s body=%s", p, safe_body)

            if p == "/favorites/add":
                manga_id = body.get("id", "")
                if not manga_id:
                    return self._error("missing id", 400)
                self._json(fav_add(manga_id, body.get("title", ""), body.get("imageUrl", "")))
            elif p == "/favorites/remove":
                manga_id = body.get("id", "")
                if not manga_id:
                    return self._error("missing id", 400)
                self._json(fav_remove(manga_id))
            elif p == "/favorites/mark-seen":
                manga_id = body.get("id", "")
                if not manga_id:
                    return self._error("missing id", 400)
                self._json(fav_mark_seen(manga_id, body.get("chapterId", "")))
            elif p == "/dl/start":
                manga_id   = body.get("mangaId", "")
                chapter_id = body.get("chapterId", "")
                if not (manga_id and chapter_id):
                    return self._error("missing mangaId or chapterId", 400)
                self._json(dl_start(manga_id, chapter_id,
                                    body.get("chapterNum", ""),
                                    body.get("chapterTitle", ""),
                                    body.get("mangaTitle", ""),
                                    body.get("rawCoverUrl", "")))
            elif p == "/dl/delete":
                chapter_id = body.get("chapterId", "")
                if not chapter_id:
                    return self._error("missing chapterId", 400)
                self._json(dl_remove(chapter_id))
            else:
                self._error("not found", 404)
            logger.info("POST done path=%s elapsed=%.3fs", p, time.monotonic() - start)

        except (BrokenPipeError, ConnectionResetError):
            logger.warning("POST client disconnected path=%s", parsed.path)
        except Exception as e:
            logger.exception("POST failed path=%s", parsed.path)
            self._error(str(e))


def run():
    if existing_server_healthy():
        logger.info("another healthy manga backend already owns port %s; exiting without starting a duplicate", PORT)
        return

    logger.info("binding server host=127.0.0.1 port=%s", PORT)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    logger.info("listening on http://127.0.0.1:%s threaded=true", PORT)
    server.serve_forever()


if __name__ == "__main__":
    try:
        run()
    except Exception:
        logger.exception("fatal server error")
        raise
