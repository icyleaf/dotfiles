# Local Manga

`local.manga` is an Omarchy panel plugin that opens a detached manga browser,
library, reader, favorites, and download window backed by a small local Python
server.

The backend scrapes WeebCentral and stores plugin data in:

```text
~/.local/share/omarchy-manga/
```

Install or copy the plugin to Omarchy's plugin directory, then rescan and
enable it:

```bash
omarchy plugin rescan
omarchy plugin enable local.manga
```

Open or toggle it with shell IPC:

```bash
omarchy-shell shell toggle local.manga '{}'
```

## Keyboard

The panel supports a Vim-like keyboard flow:

| Key | Action |
| --- | --- |
| `1` / `2` | Switch between Browse and Library |
| `h` / `j` / `k` / `l` | Move left, down, up, right in grids/lists |
| Arrow keys | Move selection |
| `Enter` / `l` | Open the selected manga or chapter |
| `h` / `Backspace` | Go back from detail or reader views |
| `g` / `G` | Jump to top or bottom |
| `/` | Toggle Browse search or focus chapter filter |
| `Esc` | Leave search/filter focus; closes the panel only when nothing inside handles it |
| `[` / `]` | Switch Browse sections |
| `s` | Toggle chapter sort in detail view |
| `d` / `u` | Scroll half-page down/up |
| `f` / `b` / `Space` | Scroll a larger page down/up |
| `l` / `Enter` in reader | Toggle the reader header |

The backend uses Python 3. If `curl_cffi` is installed it will use browser-grade
TLS impersonation; otherwise it falls back to `requests`.
