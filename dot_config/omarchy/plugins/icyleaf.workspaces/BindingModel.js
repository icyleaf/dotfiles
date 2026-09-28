.pragma library

// Workspace-binding resolution — pure decision seam for the workspace bar
// widget.
//
// Takes plain data (a normalized binding list, a window descriptor, and the
// live monitor list) and returns plain data: which workspace a newly opened
// window should be routed to and whether focus follows it. It performs no I/O
// and calls no Quickshell APIs, so the resolution rules are testable without a
// live compositor. The QML shell owns file reading, Hyprland events, monitor
// snapshots, and dispatch.

// ---------------------------------------------------------------------------
// Addresses and client parsing
// ---------------------------------------------------------------------------

function normalizeAddress(value) {
  var address = String(value === null || value === undefined ? "" : value).toLowerCase()
  return address.indexOf("0x") === 0 ? address : ""
}

// Parse `hyprctl clients -j` output into an address -> window descriptor map.
// Descriptors carry the initial class (falling back to the live class), the
// live class, and the current title. Garbage and non-arrays yield an empty map.
function parseClientWindows(text) {
  var out = {}
  var clients
  try {
    clients = JSON.parse(String(text === null || text === undefined ? "" : text))
  } catch (error) {
    return out
  }
  if (!clients || clients.length === undefined) return out
  for (var i = 0; i < clients.length; i++) {
    var client = clients[i] || {}
    var address = normalizeAddress(client.address)
    if (!address) continue
    out[address] = {
      initialClass: String(client.initialClass || client.class || ""),
      class: String(client.class || ""),
      title: String(client.title || ""),
      workspaceId: client.workspace && client.workspace.id !== undefined ? client.workspace.id : 0
    }
  }
  return out
}

// ---------------------------------------------------------------------------
// Bindings
// ---------------------------------------------------------------------------

function compile(pattern, anchored) {
  try {
    return new RegExp(anchored ? "^(" + pattern + ")$" : String(pattern))
  } catch (error) {
    return null
  }
}

function regexTest(pattern, value, anchored) {
  var re = compile(pattern, anchored)
  return re !== null && re.test(String(value))
}

// Does a window class match a binding's anchored class regex?
function classMatches(pattern, value) {
  return regexTest(pattern, value, true)
}

// One binding's stable signature, used to detect configuration changes.
function signatureFor(bindings, klass) {
  if (!bindings || bindings.length === undefined) return ""
  var parts = []
  for (var i = 0; i < bindings.length; i++) {
    if (bindings[i].class === klass) parts.push(JSON.stringify(bindings[i]))
  }
  return parts.join("|")
}

// The window classes whose bindings were added or changed between two binding
// lists. Used to re-place already-open windows of only the classes that moved,
// so editing one binding never disturbs unrelated apps.
function changedClasses(previous, next) {
  var changed = []
  var seen = {}
  if (!next || next.length === undefined) return changed
  for (var i = 0; i < next.length; i++) {
    var klass = next[i].class
    if (seen[klass]) continue
    seen[klass] = true
    if (signatureFor(previous, klass) !== signatureFor(next, klass)) changed.push(klass)
  }
  return changed
}

function normalizeMatcher(target) {
  var monitor = target && target.monitor ? target.monitor : null
  if (!monitor || typeof monitor !== "object") return null

  // Exactly one matcher key is allowed; anything else is ambiguous.
  var keys = []
  if (monitor.id !== undefined && monitor.id !== null) keys.push("id")
  if (typeof monitor.name === "string" && monitor.name !== "") keys.push("name")
  if (typeof monitor.desc === "string" && monitor.desc !== "") keys.push("desc")
  if (keys.length !== 1) return null

  if (keys[0] === "id") {
    var id = Number(monitor.id)
    return isFinite(id) ? { kind: "id", value: id } : null
  }
  if (keys[0] === "name") return { kind: "name", value: monitor.name }
  return { kind: "desc", value: monitor.desc }
}

function normalizeSlot(target) {
  var slot = Math.floor(Number(target && target.slot))
  if (!isFinite(slot) || slot < 1 || slot > 10) return null
  return slot
}

// Validate and normalize the authored binding list. Entries missing a usable
// class, carrying an uncompilable class/title regex, or naming anything other
// than exactly one monitor matcher and a slot in 1..10 are dropped. A binding
// without a title matches on class alone; `focus` defaults to silent.
function normalizeBindings(raw) {
  var out = []
  if (!raw || raw.length === undefined) return out
  for (var i = 0; i < raw.length; i++) {
    var entry = raw[i] || {}
    var klass = typeof entry.class === "string" ? entry.class : ""
    if (klass === "" || compile(klass, true) === null) continue
    var matcher = normalizeMatcher(entry.target)
    if (matcher === null) continue
    var slot = normalizeSlot(entry.target)
    if (slot === null) continue
    var title = null
    if (entry.title !== undefined && entry.title !== null && String(entry.title) !== "") {
      title = String(entry.title)
      if (compile(title, false) === null) continue
    }
    out.push({
      class: klass,
      title: title,
      matcher: matcher,
      slot: slot,
      focus: entry.focus === true
    })
  }
  return out
}

// ---------------------------------------------------------------------------
// Monitor matching
// ---------------------------------------------------------------------------

// Disabled and mirrored outputs never receive workspace bindings.
function monitorEligible(monitor) {
  return monitor && monitor.enabled !== false && monitor.mirrored !== true
}

function monitorMatches(matcher, monitor) {
  if (matcher.kind === "id") return Number(monitor.id) === matcher.value
  if (matcher.kind === "name") return String(monitor.name || "") === matcher.value
  return String(monitor.description || "").toLowerCase().indexOf(matcher.value.toLowerCase()) !== -1
}

function resolveMonitor(matcher, monitors) {
  if (!matcher || !monitors || monitors.length === undefined) return null
  var candidates = []
  for (var i = 0; i < monitors.length; i++) {
    var monitor = monitors[i]
    if (monitorEligible(monitor) && monitorMatches(matcher, monitor)) candidates.push(monitor)
  }
  if (candidates.length === 0) return null

  // An exact description beats a substring description; remaining ties break
  // toward the lowest monitor id, so a matcher that covers several panels is
  // still deterministic.
  if (matcher.kind === "desc") {
    var needle = matcher.value.toLowerCase()
    var exact = []
    for (var j = 0; j < candidates.length; j++) {
      if (String(candidates[j].description || "").toLowerCase() === needle) exact.push(candidates[j])
    }
    if (exact.length > 0) candidates = exact
  }

  var best = candidates[0]
  for (var k = 1; k < candidates.length; k++) {
    if (Number(candidates[k].id) < Number(best.id)) best = candidates[k]
  }
  return best
}

function monitorOffset(monitor) {
  var offset = Number(monitor.offset)
  if (isFinite(offset)) return offset
  return Number(monitor.id) * 10
}

function applyResult(monitor, binding) {
  return {
    status: "apply",
    workspaceId: monitorOffset(monitor) + binding.slot,
    follow: binding.focus === true,
    monitorId: Number(monitor.id),
    monitorName: String(monitor.name || "")
  }
}

// ---------------------------------------------------------------------------
// Resolution
// ---------------------------------------------------------------------------

// Resolve a window descriptor against the binding list and live monitors.
// Descriptor: { initialClass, title }.
//
// Returns one of:
//   { status: "apply",   workspaceId, follow }
//   { status: "pending" }   a class+monitor match whose title regex has not
//                           been satisfied yet (no concrete match exists)
//   { status: "none" }
//
// Bindings are scanned in source order. A binding whose monitor is absent on
// this layout is skipped so a later binding for the same class can take over.
function resolve(bindings, descriptor, monitors) {
  if (!bindings || bindings.length === undefined) return { status: "none" }
  var klass = String((descriptor && descriptor.initialClass) || "")
  var title = String((descriptor && descriptor.title) || "")
  var pending = false

  for (var i = 0; i < bindings.length; i++) {
    var binding = bindings[i]
    if (!regexTest(binding.class, klass, true)) continue
    var monitor = resolveMonitor(binding.matcher, monitors)
    if (!monitor) continue

    if (binding.title !== null && binding.title !== "") {
      if (title !== "" && regexTest(binding.title, title, false)) return applyResult(monitor, binding)
      pending = true
      continue
    }
    return applyResult(monitor, binding)
  }

  return pending ? { status: "pending" } : { status: "none" }
}
