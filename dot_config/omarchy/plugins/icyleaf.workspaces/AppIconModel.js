.pragma library

// App-icon resolution — pure decision seam for the workspace bar widget.
//
// Takes plain data (process names, `hyprctl clients -j` text, `pstree` output,
// `ls` listings, window DTOs, override entries) and returns plain data: which
// icon source a window's app should use and how to probe for it. It performs
// no I/O and calls no Quickshell APIs, so the resolution rules are testable
// without a live compositor. The QML shells own desktop-entry/icon-theme
// lookups, process execution, timers, and rendering.

// ---------------------------------------------------------------------------
// Process names and override entries
// ---------------------------------------------------------------------------

// Process names are spliced into an ERE for `pstree | grep -oE`, so they must
// be reduced to a safe alphabet: lowercase letters, digits, underscore and
// hyphen. Everything else is dropped.
function sanitizeProcessName(value) {
  return String(value === null || value === undefined ? "" : value)
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, "")
}

// Normalize the user's `iconOverrides` setting into clean {process, icon}
// entries. Entries missing a usable process name or icon are dropped.
function normalizeIconOverrides(raw) {
  var out = []
  if (!raw || raw.length === undefined) return out
  for (var i = 0; i < raw.length; i++) {
    var entry = raw[i] || {}
    var process = sanitizeProcessName(entry.process)
    var icon = String(entry.icon || "")
    if (!process || !icon) continue
    out.push({ process: process, icon: icon })
  }
  return out
}

// Every process name the probe should look for, in priority order and free of
// duplicates: explicit overrides, then icons bundled in the plugin, then the
// curated defaults. Sanitized so no name can break the probe expression.
function probeNames(overrides, bundled, knownApps) {
  var seen = {}
  var out = []

  function add(raw) {
    var name = sanitizeProcessName(raw)
    if (!name || seen[name]) return
    seen[name] = true
    out.push(name)
  }

  var overrideList = overrides || []
  for (var i = 0; i < overrideList.length; i++)
    add(overrideList[i] && overrideList[i].process)

  var bundledMap = bundled || {}
  for (var key in bundledMap) add(key)

  var known = knownApps || []
  for (var j = 0; j < known.length; j++) add(known[j])

  return out
}

// ---------------------------------------------------------------------------
// Terminal process-tree probe
// ---------------------------------------------------------------------------

// Build the shell command that scans a window's process tree and prints the
// first known app process name found. Names are sanitized and de-duplicated;
// when there are none, an expression that matches nothing is used so the probe
// can never report an arbitrary process.
function buildProbeCommand(pid, names) {
  var seen = {}
  var list = []
  var values = names || []
  for (var i = 0; i < values.length; i++) {
    var name = sanitizeProcessName(values[i])
    if (!name || seen[name]) continue
    seen[name] = true
    list.push(name)
  }
  var pattern = list.length > 0 ? list.join("|") : "\\b\\B"
  return "pstree -p " + String(parseInt(pid, 10) || 0)
    + " 2>/dev/null | grep -oE '(" + pattern + ")\\(' | head -n1 | tr -d '('"
}

// Reduce raw probe stdout to the first matched process name, or "" when the
// probe found nothing.
function parseProbeOutput(text) {
  var lines = String(text === null || text === undefined ? "" : text).split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line) return sanitizeProcessName(line)
  }
  return ""
}

// ---------------------------------------------------------------------------
// Window records from `hyprctl clients -j`
// ---------------------------------------------------------------------------

// Canonicalize a window address so toplevels (no "0x" prefix) and hyprctl
// (with "0x" prefix) can be matched against each other.
function normalizedAddress(value) {
  var address = String(value === null || value === undefined ? "" : value).trim().toLowerCase()
  if (!address.match(/^(0x)?[0-9a-f]+$/)) return ""
  return address.indexOf("0x") === 0 ? address : "0x" + address
}

// Parse `hyprctl clients -j` into an address -> { pid, area, klass } map. Live
// data is needed because Quickshell only populates a toplevel's lastIpcObject
// during its initial sync, so windows opened later carry no pid/size there.
function parseClients(text) {
  var map = {}
  var list
  try {
    list = JSON.parse(String(text === null || text === undefined ? "" : text))
  } catch (error) {
    return map
  }
  if (!list || list.length === undefined) return map
  for (var i = 0; i < list.length; i++) {
    var client = list[i] || {}
    var address = normalizedAddress(client.address)
    if (!address) continue
    var size = client.size
    var area = (size && size.length >= 2) ? Number(size[0]) * Number(size[1]) : 0
    map[address] = {
      pid: Number(client.pid) || 0,
      area: isFinite(area) && area > 0 ? area : 0,
      klass: String(client.class || "")
    }
  }
  return map
}

// ---------------------------------------------------------------------------
// Window field access (real Quickshell toplevels OR plain data fixtures)
// ---------------------------------------------------------------------------

// Read a field from a toplevel or, failing that, from its lastIpcObject map.
function field(toplevel, name) {
  if (!toplevel) return undefined
  var value = toplevel[name]
  if (value !== undefined && value !== null) return value
  var ipc = toplevel.lastIpcObject
  return ipc ? ipc[name] : undefined
}

// Live `hyprctl` record for a toplevel (pid/area/class), or null.
function clientRecord(toplevel, clientInfo) {
  var address = normalizedAddress(toplevel && toplevel.address)
  if (!address || !clientInfo) return null
  return clientInfo[address] || null
}

function windowArea(toplevel, clientInfo) {
  var info = clientRecord(toplevel, clientInfo)
  if (info && Number(info.area) > 0) return Number(info.area)
  var size = field(toplevel, "size")
  if (size && size.length >= 2) {
    var area = Number(size[0]) * Number(size[1])
    if (isFinite(area) && area > 0) return area
  }
  return 0
}

// The largest window on a workspace identifies that workspace's app. Live
// client areas win; per-toplevel size is the fallback.
function biggestWindow(toplevels, clientInfo) {
  var values = toplevels || []
  var best = null
  var bestArea = -1
  for (var i = 0; i < values.length; i++) {
    var area = windowArea(values[i], clientInfo)
    if (area > bestArea) {
      bestArea = area
      best = values[i]
    }
  }
  return best
}

function windowPid(toplevel, clientInfo) {
  var info = clientRecord(toplevel, clientInfo)
  if (info && Number(info.pid) > 0) return Number(info.pid)
  var pid = Number(field(toplevel, "pid"))
  return pid > 0 ? pid : 0
}

function windowClass(toplevel, clientInfo) {
  if (!toplevel) return ""
  var info = clientRecord(toplevel, clientInfo)
  if (info && info.klass) return String(info.klass)
  var klass = field(toplevel, "class")
  if (klass) return String(klass)
  var wayland = toplevel.wayland
  if (wayland && wayland.appId) return String(wayland.appId)
  return String(toplevel.title || "")
}

// ---------------------------------------------------------------------------
// Bundled icon directory
// ---------------------------------------------------------------------------

// Turn an `ls` listing of the plugin's icons/ directory into a basename ->
// filename map. Only .png/.svg files count; the basename is sanitized so a
// dropped-in file "Claude Code.png" matches the process "claude" only when its
// basename sanitizes to a probeable name.
function scanIconListing(text) {
  var map = {}
  var lines = String(text === null || text === undefined ? "" : text).split("\n")
  for (var i = 0; i < lines.length; i++) {
    var file = lines[i].trim()
    if (!file) continue
    var dot = file.lastIndexOf(".")
    if (dot <= 0) continue
    var ext = file.substring(dot + 1).toLowerCase()
    if (ext !== "png" && ext !== "svg") continue
    var base = sanitizeProcessName(file.substring(0, dot))
    if (base && !map[base]) map[base] = file
  }
  return map
}

// Resolve a detected process name to an icon source, or "" when nothing claims
// it (leaving the slot on the window's own class icon). Order: explicit
// override, then a bundled icon, then nothing — the icon-theme fallback is the
// shell's job because it needs Quickshell APIs.
function resolveProcessIcon(name, overrides, bundled) {
  var process = sanitizeProcessName(name)
  if (!process) return ""
  var overrideList = overrides || []
  for (var i = 0; i < overrideList.length; i++) {
    if (overrideList[i] && overrideList[i].process === process)
      return String(overrideList[i].icon || "")
  }
  var bundledMap = bundled || {}
  if (bundledMap[process]) return "icons/" + bundledMap[process]
  return ""
}

// ---------------------------------------------------------------------------
// Window class -> icon name candidates
// ---------------------------------------------------------------------------

// Icon names to try against the desktop entries and the icon theme, in order:
// the class as-is, its lowercase form, and its last reverse-domain segment
// (plus that segment lowercased). Duplicates are removed. The shell walks this
// list and stops at the first hit.
function iconNameCandidates(klass) {
  var value = String(klass === null || klass === undefined ? "" : klass).trim()
  if (!value) return []
  var out = []

  function add(name) {
    if (name && out.indexOf(name) === -1) out.push(name)
  }

  add(value)
  add(value.toLowerCase())
  var dot = value.lastIndexOf(".")
  if (dot >= 0 && dot < value.length - 1) {
    var segment = value.substring(dot + 1)
    add(segment)
    add(segment.toLowerCase())
  }
  return out
}

// Curated TUI apps that commonly run inside a terminal. Shells and
// multiplexers are deliberately absent: the probe takes the first match in the
// process tree, so listing `bash` or `tmux` would shadow whatever runs inside.
function knownTuiApps() {
  return [
    "btop", "htop", "glances", "bpytop", "ncdu", "dust", "duf",
    "nvim", "vim", "helix", "hx", "emacs", "nano", "micro",
    "yazi", "ranger", "nnn", "lf", "mc", "broot",
    "lazygit", "gitui", "tig", "lazydocker", "k9s", "kubectl",
    "claude", "opencode", "aider", "codex", "crush", "goose",
    "cava", "cmus", "ncmpcpp", "newsboat", "neomutt", "mutt",
    "irssi", "weechat", "calcurse", "taskwarrior", "btm", "bandwhich"
  ]
}
