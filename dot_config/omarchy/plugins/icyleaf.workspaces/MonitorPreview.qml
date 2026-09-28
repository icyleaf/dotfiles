import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "LayoutModel.js" as LayoutModel

// Per-Monitor Layout Preview Overlay.
//
// A full-screen, read-only spatial preview of the current multi-display setup:
// every enabled physical monitor is drawn as a card in a COMPACT PACK — rows
// preserve each display's true top→bottom and left→right relationship and
// aspect ratio, but panels are packed tightly together (rather than laid out by
// their absolute Hyprland coordinates, which would scatter them across the
// screen). Each card shows that monitor's active-workspace windows as
// rectangles plus a 10-slot occupancy strip.
//
// The widget host owns open/close lifecycle; this component is self-contained:
// it builds its own plain-data snapshot from live Hyprland objects, runs it
// through the LayoutModel seam, renders the resulting cards, and refreshes
// itself from Hyprland events while open.
PanelWindow {
  id: root

  required property Item hostBar
  property bool open: false
  property int preselectMonitorId: -1
  // A full-screen PanelWindow created as a child of a per-monitor bar surface
  // anchors to that surface's screen (same as the special-picker overlay), so
  // the overlay appears on the monitor whose badge was right-clicked. hostBar
  // may be null only transiently during construction.
  property bool windowOpen: open && hostBar !== null

  anchors { top: true; bottom: true; left: true; right: true }
  visible: root.windowOpen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "icyleaf.workspaces.layout-preview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.windowOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  readonly property string fontFamily: hostBar && hostBar.fontFamily ? hostBar.fontFamily : Style.font.family
  // Minimum visual gap between neighbouring monitor cards, in px. Real 0px
  // logical gaps (physically abutting panels) are padded up to this so each
  // panel reads as a distinct surface.
  readonly property real minCardGap: Math.max(10, Style.space(2))
  readonly property real minWindow: Math.max(Style.space(10), Style.spaceReal(14))

  // ── Live state model ──────────────────────────────────────────────────────
  property var model: ({ cards: [] })
  property int selectedIndex: -1

  // Logical monitor geometry in the shared global coordinate space. Hyprland
  // monitor x/y and client `at` are global LOGICAL px; monitor width/height
  // are PHYSICAL px, so divide by the monitor's own scale. QScreen is NOT used:
  // in a mixed-scale multi-monitor setup its device-independent size is not
  // guaranteed to match the Hyprland logical size for each output.
  function logicalMonitorGeometry(monitor) {
    if (!monitor) return null
    var scale = Number(monitor.scale) > 0 ? Number(monitor.scale) : 1
    var width = Number(monitor.width) / scale
    var height = Number(monitor.height) / scale
    if (!isFinite(width) || !isFinite(height) || width <= 0 || height <= 0) return null
    return { x: Number(monitor.x), y: Number(monitor.y), width: width, height: height }
  }

  function workspaceOnMonitor(workspace, monitorName) {
    var target = workspace && workspace.monitor
      ? String(workspace.monitor.name || "") : String(workspace.lastIpcObject && workspace.lastIpcObject.monitor || "")
    return target === monitorName
  }

  function buildSnapshot() {
    var monitors = Hyprland.monitors.values
    var workspaces = Hyprland.workspaces.values
    var monitorList = []
    var focusedWorkspaceId = Hyprland.focusedWorkspace ? Number(Hyprland.focusedWorkspace.id) : 0

    for (var i = 0; i < monitors.length; i++) {
      var monitor = monitors[i]
      var name = String(monitor.name || "")
      var geo = root.logicalMonitorGeometry(monitor)
      if (!geo) continue

      // Occupied workspace ids on this monitor (regular workspaces only). A
      // workspace counts as occupied only when it actually has windows on it;
      // Hyprland also lists an empty active workspace, which must stay "empty".
      var occupiedIds = []
      for (var w = 0; w < workspaces.length; w++) {
        var ws = workspaces[w]
        var wsId = Number(ws.id)
        if (wsId > 0 && root.workspaceOnMonitor(ws, name)
            && ws.toplevels && ws.toplevels.values.length > 0)
          occupiedIds.push(wsId)
      }

      var activeWorkspace = monitor.activeWorkspace
      var activeWorkspaceId = activeWorkspace ? Number(activeWorkspace.id) : 0
      var rawWindows = []
      if (activeWorkspace && activeWorkspace.toplevels)
        rawWindows = activeWorkspace.toplevels.values.slice()

      var monitorScale = Number(monitor.scale) > 0 ? Number(monitor.scale) : 1
      monitorList.push({
        id: Number(monitor.id),
        name: name,
        description: String(monitor.description || ""),
        x: geo.x,
        y: geo.y,
        width: geo.width,
        height: geo.height,
        physicalWidth: Math.round(geo.width * monitorScale),
        physicalHeight: Math.round(geo.height * monitorScale),
        scale: monitorScale,
        focused: monitor.focused === true,
        offset: Number(monitor.id) * 10,
        activeWorkspaceId: activeWorkspaceId,
        occupiedIds: occupiedIds,
        windows: rawWindows
      })
    }

    return { focusedWorkspaceId: focusedWorkspaceId, monitors: monitorList }
  }

  function recompute() {
    var usableW = Math.max(1, root.width)
    var usableH = Math.max(1, root.height)
    root.model = LayoutModel.build(root.buildSnapshot(), usableW, usableH, root.minCardGap, root.minWindow)

    var cards = root.model.cards
    if (root.selectedIndex < 0 || root.selectedIndex >= cards.length) {
      root.selectedIndex = root.indexForMonitorId(root.preselectMonitorId)
      if (root.selectedIndex < 0 && cards.length > 0) root.selectedIndex = 0
    }
  }

  function indexForMonitorId(id) {
    var cards = root.model.cards
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].id === id) return i
    }
    return -1
  }

  function focusMonitorByName(name) {
    if (!name) return
    Hyprland.dispatch("function() hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(name) + " })) end")
  }

  function quoteLua(value) {
    return "\"" + String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\""
  }

  function activateCard(index) {
    var cards = root.model.cards
    if (index < 0 || index >= cards.length) return
    root.focusMonitorByName(cards[index].name)
    root.open = false
  }

  function dismiss() { root.open = false }

  function openFor(monitorId) {
    root.preselectMonitorId = monitorId
    root.open = true
    // onOpenChanged fires root.recompute() when this transitions closed→open.
    Qt.callLater(function() { navCatcher.forceActiveFocus() })
  }

  function close() {
    root.open = false
  }

  // ── Live refresh while open ───────────────────────────────────────────────
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!root.windowOpen || !event || !event.name) return
      var name = String(event.name)
      var interesting = name.indexOf("monitor") !== -1
        || name.indexOf("workspace") !== -1
        || name.indexOf("window") !== -1
        || name.indexOf("group") !== -1
        || name === "fullscreen"
        || name === "changefloatingmode"
        || name === "focusedmon"
      if (interesting) {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
        root.recompute()
      }
    }
  }

  // ── Scrim ─────────────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.62)
    opacity: root.windowOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // Empty-space (and any right) click dismisses.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: root.dismiss()
    }

    // ── Card scene ──────────────────────────────────────────────────────────
    Item {
      anchors.fill: parent

      Repeater {
        model: root.model.cards

        MonitorCard {
          required property var modelData
          required property int index

          x: modelData.x
          y: modelData.y
          width: modelData.width
          height: modelData.height
          cardModel: modelData
          selected: index === root.selectedIndex
          fontFamily: root.fontFamily
          z: index + 1

          onActivated: function(monitorId) { root.activateCard(root.indexForMonitorId(monitorId)) }
        }
      }
    }

    // ── Keyboard navigation (T5) ────────────────────────────────────────────
    // A transparent, non-interactive Item that owns key focus while the
    // overlay is open. It does not paint and does not capture the mouse, so it
    // never blocks card clicks; it only routes keyboard input.
    Item {
      id: navCatcher
      anchors.fill: parent
      visible: root.windowOpen
      focus: root.windowOpen

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
          return
        }
        var dx = 0
        var dy = 0
        if (event.key === Qt.Key_Left) dx = -1
        else if (event.key === Qt.Key_Right) dx = 1
        else if (event.key === Qt.Key_Up) dy = -1
        else if (event.key === Qt.Key_Down) dy = 1
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activateCard(root.selectedIndex)
          event.accepted = true
          return
        }
        if (dx !== 0 || dy !== 0) {
          root.selectedIndex = root.navTarget(root.selectedIndex, dx, dy)
          event.accepted = true
        }
      }
    }
  }

  // Move card selection. Horizontal moves to the nearest card left/right by
  // vertical overlap; vertical moves to the nearest card above/below by
  // horizontal overlap. Falls back to ordering by position when no overlap.
  function navTarget(fromIndex, dx, dy) {
    var cards = root.model.cards
    if (cards.length === 0) return -1
    if (fromIndex < 0 || fromIndex >= cards.length) return 0
    var from = cards[fromIndex]
    if (cards.length === 1) return fromIndex

    var best = -1
    var bestScore = Infinity
    for (var i = 0; i < cards.length; i++) {
      if (i === fromIndex) continue
      var c = cards[i]
      var score
      if (dx !== 0) {
        // Moving horizontally: candidate must be strictly in that direction.
        if (dx < 0 && c.x + c.width > from.x + 0.5) continue
        if (dx > 0 && c.x < from.x + from.width - 0.5) continue
        var overlapY = Math.min(from.y + from.height, c.y + c.height) - Math.max(from.y, c.y)
        score = Math.abs(c.x + c.width / 2 - (from.x + from.width / 2)) - overlapY
      } else {
        if (dy < 0 && c.y + c.height > from.y + 0.5) continue
        if (dy > 0 && c.y < from.y + from.height - 0.5) continue
        var overlapX = Math.min(from.x + from.width, c.x + c.width) - Math.max(from.x, c.x)
        score = Math.abs(c.y + c.height / 2 - (from.y + from.height / 2)) - overlapX
      }
      if (score < bestScore) { bestScore = score; best = i }
    }
    return best >= 0 ? best : fromIndex
  }

  onOpenChanged: if (root.open) root.recompute()
  onWidthChanged: if (root.windowOpen) root.recompute()
  onHeightChanged: if (root.windowOpen) root.recompute()
}
