.pragma library

// Per-Monitor Layout Preview — pure geometry/model seam.
//
// Takes a plain-data snapshot of the Hyprland monitor topology (global x/y
// coordinates in compositor space, physical sizes, scale factors, per-monitor
// workspace occupancy and active-workspace window DTOs) and returns a fully
// laid-out model of monitor cards ready for the overlay to render: each card's
// position and size preserve the true spatial relations of the real displays,
// scaled uniformly onto the given canvas; windows project into card-local
// coordinates at the same uniform scale.

function finiteNumber(value) {
  var number = Number(value)
  return isFinite(number) ? number : NaN
}

function clamp(value, minimum, maximum) {
  return Math.max(minimum, Math.min(value, maximum))
}

// ---------------------------------------------------------------------------
// Toplevel collapsing (Hyprland groups → single preview units)
// ---------------------------------------------------------------------------

function normalizedAddress(value) {
  var address = String(value || "").trim().toLowerCase()
  if (!address.match(/^(0x)?[0-9a-f]+$/)) return ""
  return address.indexOf("0x") === 0 ? address : "0x" + address
}

function ipcObject(toplevel) {
  return toplevel && toplevel.lastIpcObject ? toplevel.lastIpcObject : null
}

// Read a field that may live on the toplevel itself (plain DTOs / real QML
// properties) or in its lastIpcObject map (real Quickshell HyprlandToplevels).
function dtoField(toplevel, name) {
  if (!toplevel) return undefined
  var value = toplevel[name]
  if (value !== undefined && value !== null) return value
  var ipc = toplevel.lastIpcObject
  return ipc ? ipc[name] : undefined
}

function groupAddresses(toplevel) {
  var grouped = dtoField(toplevel, "grouped")
  if (!grouped || typeof grouped.length !== "number") return []
  if (grouped.length === 0) return []

  var addresses = []
  for (var i = 0; i < grouped.length; i++) {
    var address = normalizedAddress(grouped[i])
    if (address && addresses.indexOf(address) === -1) addresses.push(address)
  }
  var own = toplevelAddress(toplevel)
  if (own && addresses.indexOf(own) === -1) addresses.push(own)
  return own && addresses.length >= 2 ? addresses : []
}

function componentRoot(parents, address) {
  var root = address
  while (parents[root] && parents[root] !== root) root = parents[root]
  while (parents[address] && parents[address] !== address) {
    var next = parents[address]
    parents[address] = root
    address = next
  }
  return root
}

function unionAddresses(parents, left, right) {
  if (!parents[left]) parents[left] = left
  if (!parents[right]) parents[right] = right
  var leftRoot = componentRoot(parents, left)
  var rightRoot = componentRoot(parents, right)
  if (leftRoot !== rightRoot) parents[rightRoot] = leftRoot
}

// Pick which member of a group represents the whole group. Prefers: not
// hidden → the active window address → accepts input → lowest focus history →
// visible, with a stable fallback so ordering never churns.
function betterGroupRepresentative(candidate, current, activeAddress) {
  if (!current) return true

  var candidateHidden = dtoField(candidate, "hidden") === true
  var currentHidden = dtoField(current, "hidden") === true
  if (!candidateHidden && currentHidden) return true
  if (candidateHidden && !currentHidden) return false

  var normActive = normalizedAddress(activeAddress)
  if (normActive) {
    var candidateAddr = toplevelAddress(candidate)
    var currentAddr = toplevelAddress(current)
    if (candidateAddr === normActive && currentAddr !== normActive) return true
    if (candidateAddr !== normActive && currentAddr === normActive) return false
  }

  var candidateInput = dtoField(candidate, "acceptsInput") === true
  var currentInput = dtoField(current, "acceptsInput") === true
  if (candidateInput && !currentInput) return true
  if (!candidateInput && currentInput) return false

  var candidateFocus = Number(dtoField(candidate, "focusHistoryID"))
  var currentFocus = Number(dtoField(current, "focusHistoryID"))
  var candidateHasFocus = isFinite(candidateFocus) && candidateFocus >= 0
  var currentHasFocus = isFinite(currentFocus) && currentFocus >= 0
  if (candidateHasFocus && !currentHasFocus) return true
  if (!candidateHasFocus && currentHasFocus) return false
  if (candidateHasFocus && currentHasFocus && candidateFocus !== currentFocus)
    return candidateFocus < currentFocus

  if (dtoField(candidate, "visible") === true && dtoField(current, "visible") !== true) return true
  if (dtoField(candidate, "visible") !== true && dtoField(current, "visible") === true) return false
  return false
}

function toplevelAddress(toplevel) {
  var ipc = ipcObject(toplevel)
  return normalizedAddress((toplevel && toplevel.address) || (ipc && ipc.address))
}

// Collapse an array of workspace toplevels (real Quickshell HyprlandToplevel
// objects OR plain DTOs with lastIpcObject/address) into preview units: each
// ungrouped window stays one unit; each Hyprland group becomes one unit sized
// like its active/representative member and tagged with its member count.
function collapseGroups(clients, activeAddress) {
  var values = clients || []
  var parents = {}
  var ownAddresses = []

  for (var i = 0; i < values.length; i++) {
    var ownAddress = toplevelAddress(values[i])
    var addresses = groupAddresses(values[i])
    ownAddresses[i] = ownAddress
    if (addresses.length < 2) continue
    for (var j = 0; j < addresses.length; j++)
      unionAddresses(parents, ownAddress, addresses[j])
  }

  var groupMembersMap = {}
  var representatives = {}
  var keys = []

  for (var k = 0; k < values.length; k++) {
    var candidateAddress = ownAddresses[k]
    var key = candidateAddress && parents[candidateAddress]
      ? componentRoot(parents, candidateAddress) : ""
    keys[k] = key
    if (key) {
      if (!groupMembersMap[key]) groupMembersMap[key] = []
      groupMembersMap[key].push(values[k])
      if (betterGroupRepresentative(values[k], representatives[key], activeAddress))
        representatives[key] = values[k]
    }
  }

  var result = []
  var seenKeys = {}
  for (var m = 0; m < values.length; m++) {
    var clientKey = keys[m]
    var client = values[m]
    if (!clientKey) {
      result.push(makeUnit(client))
    } else if (!seenKeys[clientKey]) {
      seenKeys[clientKey] = true
      var rep = representatives[clientKey] || client
      var members = groupMembersMap[clientKey] || [rep]
      result.push(makeUnit(rep, members.length))
    }
  }
  return result
}

function makeUnit(toplevel, memberCount) {
  var ipc = ipcObject(toplevel) || {}
  return {
    address: toplevelAddress(toplevel),
    title: String((toplevel && toplevel.title) || ipc.title || "Window"),
    groupSize: memberCount || 1,
    ipc: ipc
  }
}

// ---------------------------------------------------------------------------
// Monitor card layout on a canvas
// ---------------------------------------------------------------------------

function logicalGeometry(monitor) {
  var x = finiteNumber(monitor.x)
  var y = finiteNumber(monitor.y)
  var width = finiteNumber(monitor.width)
  var height = finiteNumber(monitor.height)
  if (!isFinite(x) || !isFinite(y) || !isFinite(width) || !isFinite(height)
      || width <= 0 || height <= 0)
    return null
  return { x: x, y: y, width: width, height: height }
}

function slotStateFor(offset, slotIndex, occupiedIds, activeId, focusedId) {
  var id = offset + slotIndex + 1
  var active = activeId === id
  return {
    id: id,
    occupied: occupiedIds.indexOf(id) !== -1,
    active: active,
    focused: focusedId === id && active
  }
}

// Window DTOs live in the same global coordinate space as monitors. Project a
// window's rectangle into card-local pixels, preserving aspect and position.
function projectWindow(ipc, card, scale, originX, originY, minW, minH) {
  var at = ipc && ipc.at, size = ipc && ipc.size
  if (!at || !size || at.length < 2 || size.length < 2) return null

  var rawX = finiteNumber(at[0])
  var rawY = finiteNumber(at[1])
  var rawWidth = finiteNumber(size[0])
  var rawHeight = finiteNumber(size[1])
  if (!isFinite(rawX) || !isFinite(rawY) || !isFinite(rawWidth)
      || !isFinite(rawHeight) || rawWidth <= 0 || rawHeight <= 0)
    return null

  var localLeft = (rawX - originX) * scale
  var localTop = (rawY - originY) * scale
  var localWidth = rawWidth * scale
  var localHeight = rawHeight * scale

  // Expand too-small windows around their center to a readable minimum,
  // clamped so they never escape the card's canvas.
  var displayWidth = Math.min(card.width, Math.max(minW, localWidth))
  var displayHeight = Math.min(card.height, Math.max(minH, localHeight))
  var x = clamp(localLeft + (localWidth - displayWidth) / 2, 0,
    Math.max(0, card.width - displayWidth))
  var y = clamp(localTop + (localHeight - displayHeight) / 2, 0,
    Math.max(0, card.height - displayHeight))

  return { x: x, y: y, width: displayWidth, height: displayHeight }
}

function makeWindowPreview(unit, ipc, card, scale, originX, originY, minW, minH) {
  var geometry = projectWindow(ipc, card, scale, originX, originY, minW, minH)
  if (!geometry) return null
  // Return card-local coordinates (relative to the card's top-left) so the
  // overlay can place window rects directly inside a positioned card.
  return {
    address: unit.address,
    title: unit.title,
    groupSize: unit.groupSize,
    x: geometry.x,
    y: geometry.y,
    width: geometry.width,
    height: geometry.height
  }
}

// Build the complete overlay layout model from a plain-data snapshot.
//
// snapshot shape (all arrays/objects are plain JS):
//   {
//     focusedWorkspaceId: int,
//     monitors: [{
//       id, name, description, x, y, width, height, focused: bool,
//       offset,                       // first workspace id of this monitor
//       activeWorkspaceId,            // may be null/0 for a fresh monitor
//       occupiedIds: [int],           // workspace ids with any windows
//       windows: [{                   // raw toplevel DTOs on the ACTIVE workspace
//         address, title, lastIpcObject?: { at, size, grouped, ... },
//         at, size, floating, grouped, ...   // flattened convenience fields
//       }]
//     }]
//   }
//
// canvasWidth/Height: the overlay's available drawing area (logical px).
// spacing: the minimum gap (px) between packed cards.
// minWindowSize: minimum readable window size in px (height derives ~0.7x).
//
// LAYOUT: monitors are laid out as a COMPACT PACK, not by their absolute
// Hyprland coordinates. Real multi-monitor coordinates frequently place panels
// far apart (or touching at exact 0px seams), which — if honoured literally —
// scatters the cards across the canvas with large empty areas. Instead the
// relative structure is preserved and then compacted:
//   1. Monitors whose vertical spans overlap are grouped into the same ROW.
//   2. Each row keeps monitors in their true left→right order, left-aligned
//      with the requested gap; each card keeps its true vertical offset within
//      its row so naturally staggered tops survive.
//   3. Rows are stacked top→bottom by their true order with the gap between.
//   4. The whole packed block is uniformly scaled to FIT the canvas and
//      centered. Real aspect ratios are preserved throughout.
function build(snapshot, canvasWidth, canvasHeight, spacing, minWindowSize) {
  var monitors = (snapshot && snapshot.monitors) || []
  var focusedWorkspaceId = Number(snapshot && snapshot.focusedWorkspaceId)
  var cw = Math.max(1, finiteNumber(canvasWidth) || 1)
  var ch = Math.max(1, finiteNumber(canvasHeight) || 1)
  var minGap = Math.max(0, finiteNumber(spacing) || 0)
  var minW = Math.max(1, finiteNumber(minWindowSize) || 1)
  var minH = Math.max(1, Math.round(minW * 0.7))

  var geoms = []
  var monitorsMeta = []
  for (var i = 0; i < monitors.length; i++) {
    var m = monitors[i]
    var g = logicalGeometry(m)
    if (!g) continue
    geoms.push(g)
    monitorsMeta.push(m)
  }

  if (geoms.length === 0) return { cards: [], scale: 0 }

  // ── Row clustering: monitors whose vertical spans overlap share a row. ──
  // eDP-1 (y0..1000) and DP-2 (y0..1080) overlap → same row; DP-1 (-1080..0)
  // merely touches eDP-1 at 0 → its own row.
  function overlaps(a, b) {
    return Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y) > 0.5
  }

  var ordered = []
  for (var oi = 0; oi < geoms.length; oi++) ordered.push(oi)
  ordered.sort(function(a, b) {
    var ca = geoms[a].y + geoms[a].height / 2
    var cb = geoms[b].y + geoms[b].height / 2
    if (ca !== cb) return ca - cb
    return geoms[a].x - geoms[b].x
  })

  var rows = [] // array of arrays of indices, top row first
  for (var ri = 0; ri < ordered.length; ri++) {
    var idx = ordered[ri]
    var placed = false
    for (var rr = 0; rr < rows.length; rr++) {
      var candidate = rows[rr][0]
      // Rows are ordered top→bottom; a monitor may join the current row only
      // if it vertically overlaps that row's established members.
      if (overlaps(geoms[idx], geoms[candidate])) {
        rows[rr].push(idx)
        placed = true
        break
      }
    }
    if (!placed) rows.push([idx])
  }

  // Sort each row left→right by monitor x.
  for (var sri = 0; sri < rows.length; sri++) {
    rows[sri].sort(function(a, b) { return geoms[a].x - geoms[b].x })
  }

  // ── Compact-pack layout ───────────────────────────────────────────────────
  // Gaps are requested in FINAL on-screen pixels; the pack is built in monitor
  // logical units and later scaled to fit the canvas. To make the requested
  // gap land at `minGap` px AFTER scaling, gaps in layout units must be
  // minGap/scale — but scale depends on the packed extent, which depends on the
  // gap. Resolve by iteration (two passes converge for a handful of monitors).
  var gapUnits = minGap > 0 ? 1 : 0
  var scale = 1
  var layout = null
  var blockWidth = 0
  var blockHeight = 0
  for (var ip = 0; ip < 3; ip++) {
    // Convert the screen-px gap to layout units using the current scale.
    gapUnits = minGap > 0 ? (minGap / Math.max(0.0001, scale)) : 0

    blockWidth = 0
    for (var bw = 0; bw < rows.length; bw++) {
      var wsum = 0
      for (var bwi = 0; bwi < rows[bw].length; bwi++) wsum += geoms[rows[bw][bwi]].width
      wsum += (rows[bw].length - 1) * gapUnits
      blockWidth = Math.max(blockWidth, wsum)
    }
    blockHeight = 0
    for (var bh = 0; bh < rows.length; bh++) {
      var rowHh = 0
      for (var bhi = 0; bhi < rows[bh].length; bhi++)
        rowHh = Math.max(rowHh, geoms[rows[bh][bhi]].height)
      blockHeight += rowHh
      if (bh < rows.length - 1) blockHeight += gapUnits
    }

    // Pack rows: accumulate heights top→bottom, centering each row under the
    // widest; each card keeps its row-relative x and its stagger offset.
    layout = []
    var yCursor = 0
    for (var lr = 0; lr < rows.length; lr++) {
      var prow = rows[lr]
      var rowW = 0
      for (var lwi = 0; lwi < prow.length; lwi++) rowW += geoms[prow[lwi]].width
      rowW += (prow.length - 1) * gapUnits
      var leftX = (blockWidth - rowW) / 2
      var xCursor = leftX
      var rowMinY = Infinity
      for (var rmc = 0; rmc < prow.length; rmc++) rowMinY = Math.min(rowMinY, geoms[prow[rmc]].y)
      var rowH = 0
      for (var rmc2 = 0; rmc2 < prow.length; rmc2++)
        rowH = Math.max(rowH, geoms[prow[rmc2]].height)
      for (var rci = 0; rci < prow.length; rci++) {
        var gi = prow[rci]
        var gg = geoms[gi]
        layout[gi] = { x: xCursor, y: yCursor + (gg.y - rowMinY) }
        xCursor += gg.width + gapUnits
      }
      yCursor += rowH + gapUnits
    }

    var newScale = Math.min(cw / blockWidth, ch / blockHeight)
    if (!isFinite(newScale) || newScale <= 0) break
    scale = newScale
  }

  // ── Scale the packed layout to the canvas and center it. ──
  var renderedW = blockWidth * scale
  var renderedH = blockHeight * scale
  var ox = (cw - renderedW) / 2
  var oy = (ch - renderedH) / 2
  var placements = []
  for (var li = 0; li < layout.length; li++) {
    var L = layout[li]
    placements.push({ x: ox + L.x * scale, y: oy + L.y * scale })
  }

  var cards = []
  for (var j = 0; j < monitorsMeta.length; j++) {
    var meta = monitorsMeta[j]
    var geo = geoms[j]
    var placed = placements[j]

    var cardWidth = geo.width * scale
    var cardHeight = geo.height * scale
    var cardX = placed.x
    var cardY = placed.y

    var offset = Math.max(0, finiteNumber(meta.offset) || 0)
    var occupiedIds = meta.occupiedIds || []
    var activeId = Number(meta.activeWorkspaceId)
    var slots = []
    for (var s = 0; s < 10; s++)
      slots.push(slotStateFor(offset, s, occupiedIds, activeId, focusedWorkspaceId))

    var rawWindows = meta.windows || []
    var units = collapseGroups(rawWindows)
    var windows = []
    for (var w = 0; w < units.length; w++) {
      var unit = units[w]
      var ipc = (unit.ipc && unit.ipc.at) ? unit.ipc
        : flatIpc(unit.address, rawWindows)
      if (!ipc) continue
      var preview = makeWindowPreview(unit, ipc, {
        x: cardX, y: cardY, width: cardWidth, height: cardHeight
      }, scale, geo.x, geo.y, minW, minH)
      if (preview) windows.push(preview)
    }

    cards.push({
      id: Number(meta.id),
      name: String(meta.name || ""),
      description: String(meta.description || ""),
      badgeText: "M" + (j + 1),
      physicalWidth: Number(meta.physicalWidth) || Math.round(geo.width * (Number(meta.scale) || 1)),
      physicalHeight: Number(meta.physicalHeight) || Math.round(geo.height * (Number(meta.scale) || 1)),
      scale: Number(meta.scale) || 1,
      focused: meta.focused === true,
      x: cardX,
      y: cardY,
      width: cardWidth,
      height: cardHeight,
      empty: windows.length === 0,
      slots: slots,
      windows: windows
    })
  }

  return { cards: cards, scale: scale }
}

// Resolve a unit's flattened geometry when the DTO did not carry lastIpcObject.
function flatIpc(address, rawWindows) {
  for (var i = 0; i < rawWindows.length; i++) {
    var candidate = rawWindows[i]
    if (normalizedAddress(candidate.address) === address) {
      var ipc = candidate.lastIpcObject || {}
      if (ipc.at && ipc.size) return ipc
      if (candidate.at && candidate.size)
        return { at: candidate.at, size: candidate.size }
      return null
    }
  }
  return null
}
