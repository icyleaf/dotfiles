import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool holdMode: true
  property string ringId: "main"
  property int selectedIndex: -1
  property real centerX: 0
  property real centerY: 0
  property real pendingCenterX: -1
  property real pendingCenterY: -1
  property bool centerPending: false
  property real lastMouseX: -1
  property real lastMouseY: -1
  property int configRevision: 0

  property var defaultConfig: ({
    "defaultRing": "main",
    "rings": [
      {
        "id": "main",
        "label": "Orbit",
        "description": "Everyday mouse-first actions.",
        "actions": [
          {
            "label": "Launcher",
            "icon": "󰍉",
            "command": "omarchy-shell shell toggle omarchy.launcher '{}'"
          },
          {
            "label": "Dictation",
            "icon": "󰍬",
            "command": "voxtype record toggle"
          },
          {
            "label": "Clipboard",
            "icon": "",
            "command": "omarchy-shell shell toggle omarchy.clipboard"
          },
          {
            "label": "Dev",
            "icon": "",
            "ring": "dev"
          },
          {
            "label": "Screenshot",
            "icon": "",
            "command": "omarchy capture screenshot region copy"
          },
          {
            "label": "Window",
            "icon": "󰖲",
            "ring": "window"
          },
          {
            "label": "Back",
            "icon": "",
            "command": "hyprctl dispatch 'hl.dsp.send_shortcut({ mods = \"ALT\", key = \"LEFT\" })'"
          },
          {
            "label": "Emoji",
            "icon": "󰞅",
            "command": "omarchy-shell shell toggle omarchy.emojis"
          }
        ]
      },
      {
        "id": "window",
        "label": "Window",
        "description": "Window and workspace controls.",
        "actions": [
          {
            "label": "Main",
            "icon": "󰁍",
            "ring": "main"
          },
          {
            "label": "Float",
            "icon": "󰖯",
            "command": "hyprctl dispatch 'hl.dsp.window.float()'"
          },
          {
            "label": "Fullscreen",
            "icon": "󰊓",
            "command": "hyprctl dispatch 'hl.dsp.window.fullscreen()'"
          },
          {
            "label": "Close",
            "icon": "",
            "command": "hyprctl dispatch 'hl.dsp.window.close()'"
          },
          {
            "label": "Scratchpad",
            "icon": "󰏖",
            "command": "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"scratchpad\")'"
          },
          {
            "label": "To Scratch",
            "icon": "󰘕",
            "command": "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:scratchpad\", follow = false })'"
          },
          {
            "label": "Prev WS",
            "icon": "",
            "command": "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'"
          },
          {
            "label": "Next WS",
            "icon": "",
            "command": "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'"
          }
        ]
      },
      {
        "id": "dev",
        "label": "Dev",
        "description": "Development and shell maintenance.",
        "actions": [
          {
            "label": "Main",
            "icon": "󰁍",
            "ring": "main"
          },
          {
            "label": "Terminal",
            "icon": "",
            "command": "omarchy launch terminal"
          },
          {
            "label": "Editor",
            "icon": "",
            "command": "omarchy-launch-editor"
          },
          {
            "label": "Files",
            "icon": "",
            "command": "omarchy launch nautilus"
          },
          {
            "label": "Herdr",
            "icon": "",
            "command": "omarchy-launch-terminal bash -c 'herdr'"
          },
          {
            "label": "Settings",
            "icon": "",
            "command": "omarchy-shell shell toggle local.settings"
          },
          {
            "label": "Restart Shell",
            "icon": "",
            "command": "omarchy restart shell"
          },
          {
            "label": "Reload Hypr",
            "icon": "󰑓",
            "command": "hyprctl reload"
          }
        ]
      }
    ]
  }
  )
  property var config: defaultConfig

  readonly property string configPath: {
    var custom = String(Quickshell.env("OMARCHY_LOCAL_ORBIT_CONFIG") || "").trim()
    return custom !== "" ? expandPath(custom) : expandPath("~/.config/omarchy/local.orbit.json")
  }
  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "local.orbit"
  readonly property var actions: {
    var rev = configRevision
    return normalizedActionsForRing(ringId)
  }
  readonly property int actionCount: actions.length

  readonly property color foreground: Color.popups.text
  readonly property color background: Color.popups.background
  readonly property color border: Color.popups.border
  readonly property color accent: Color.accent
  readonly property color urgent: Color.urgent
  readonly property color scrim: "transparent"
  readonly property color ringTrack: Util.alpha(foreground, 0.26)
  readonly property color ringHighlight: Util.alpha(accent, 0.82)
  readonly property color ringOutline: Util.alpha(foreground, 0.32)
  readonly property string fontFamily: Style.font.family
  readonly property string iconFontFamily: "Symbols Nerd Font"
  readonly property int ringInnerRadius: Style.space(54)
  readonly property int ringOuterRadius: Style.space(158)
  readonly property int ringMidRadius: Math.round((ringInnerRadius + ringOuterRadius) / 2)
  readonly property int ringWidth: Math.max(Style.space(34), ringOuterRadius - ringInnerRadius)
  readonly property int itemRadius: Style.space(126)
  readonly property int guideRadius: itemRadius
  readonly property int itemSize: Style.space(68)
  readonly property int centerSize: Style.space(116)
  readonly property int edgePadding: Math.max(Style.gapsOut + itemSize / 2 + Style.space(8), ringOuterRadius + Style.space(12))

  onSelectedIndexChanged: ringCanvas.requestPaint()
  onActionCountChanged: {
    if (selectedIndex >= actionCount) selectedIndex = -1
    ringCanvas.requestPaint()
  }
  onCenterXChanged: ringCanvas.requestPaint()
  onCenterYChanged: ringCanvas.requestPaint()
  onOpenedChanged: {
    if (opened) {
      applyPendingCenter()
      ringCanvas.requestPaint()
    }
  }

  function expandPath(path) {
    var value = String(path || "").trim()
    var home = Quickshell.env("HOME") || ""
    if (value === "~") return home
    if (value.indexOf("~/") === 0) return home + value.substring(1)
    if (value.indexOf("$HOME/") === 0) return home + value.substring(5)
    return value
  }

  function parseJson(value, fallback) {
    try { return JSON.parse(String(value || "{}")) || fallback } catch (e) { return fallback }
  }

  function loadConfig(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      config = defaultConfig
      configRevision++
      return
    }

    var parsed = parseJson(text, null)
    if (!parsed) {
      console.warn("orbit: ignoring invalid config", configPath)
      config = defaultConfig
      configRevision++
      return
    }

    if (Array.isArray(parsed)) parsed = { defaultRing: "main", rings: [{ id: "main", label: "Orbit", actions: parsed }] }
    else if (Array.isArray(parsed.actions)) parsed = { defaultRing: parsed.defaultRing || "main", rings: [{ id: parsed.id || "main", label: parsed.label || "Orbit", description: parsed.description || "", actions: parsed.actions }] }

    if (!Array.isArray(parsed.rings) || parsed.rings.length === 0) {
      console.warn("orbit: config has no rings; using defaults", configPath)
      config = defaultConfig
    } else {
      config = parsed
    }
    configRevision++
  }

  function rings() {
    var c = config || defaultConfig
    return Array.isArray(c.rings) && c.rings.length > 0 ? c.rings : defaultConfig.rings
  }

  function defaultRingId() {
    var c = config || defaultConfig
    if (c.defaultRing) return String(c.defaultRing)
    var rs = rings()
    return rs.length > 0 && rs[0].id ? String(rs[0].id) : "main"
  }

  function ringFor(id) {
    var wanted = String(id || "")
    var rs = rings()
    for (var i = 0; i < rs.length; i++) {
      var ring = rs[i] || ({})
      if (String(ring.id || ring.name || "") === wanted) return ring
    }
    return rs.length > 0 ? rs[0] : defaultConfig.rings[0]
  }

  function ringLabel() {
    var ring = ringFor(ringId)
    return String((ring && (ring.label || ring.name || ring.id)) || "Orbit")
  }

  function ringDescription() {
    var ring = ringFor(ringId)
    return String((ring && ring.description) || (holdMode ? "Release to choose" : "Click a slice to choose"))
  }

  function normalizedActionsForRing(id) {
    var ring = ringFor(id)
    var source = ring && Array.isArray(ring.actions) ? ring.actions : []
    var out = []
    for (var i = 0; i < source.length; i++) {
      var action = normalizeAction(source[i], i)
      if (action) out.push(action)
    }
    return out
  }

  function normalizeAction(value, index) {
    if (typeof value === "string") return { label: value, icon: String(index + 1), command: value }
    if (!value || typeof value !== "object") return null
    var label = String(value.label || value.name || value.title || value.command || value.ring || ("Action " + (index + 1)))
    return {
      label: label,
      description: String(value.description || value.tooltip || ""),
      icon: String(value.icon || value.glyph || String(index + 1)),
      command: value.command || value.exec || "",
      argv: value.argv || null,
      ring: value.ring || value.subring || "",
      close: value.close === true
    }
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, Number(value)))
  }

  function usableCenterX(x) {
    if (panel.width <= 0) return 0
    if (!isFinite(x) || x < 0) return panel.width / 2
    return clamp(x, Math.min(edgePadding, panel.width / 2), Math.max(panel.width / 2, panel.width - edgePadding))
  }

  function usableCenterY(y) {
    if (panel.height <= 0) return 0
    if (!isFinite(y) || y < 0) return panel.height / 2
    return clamp(y, Math.min(edgePadding, panel.height / 2), Math.max(panel.height / 2, panel.height - edgePadding))
  }

  function panelReadyForCursor() {
    if (panel.width <= 0 || panel.height <= 0) return false

    var screenW = panel.screen ? Number(panel.screen.width || 0) : 0
    var screenH = panel.screen ? Number(panel.screen.height || 0) : 0
    if (screenW > 0 && screenH > 0) {
      return panel.width >= screenW * 0.9 && panel.height >= screenH * 0.9
    }

    return panel.width >= edgePadding * 4 && panel.height >= edgePadding * 4
  }

  function queueCenter(payload) {
    pendingCenterX = payload && payload.x !== undefined ? Number(payload.x) : -1
    pendingCenterY = payload && payload.y !== undefined ? Number(payload.y) : -1
    centerPending = true
    applyPendingCenter()
  }

  function applyPendingCenter() {
    if (!centerPending || !opened) return

    // On the first summon Quickshell can report a placeholder surface size
    // before the layer-shell surface is actually fullscreen. If we clamp
    // against that transient size, the ring lands near the top-left and then
    // never corrects. Wait until the panel roughly matches the screen before
    // consuming the pending cursor position.
    if (!panelReadyForCursor()) return

    centerX = usableCenterX(pendingCenterX)
    centerY = usableCenterY(pendingCenterY)
    centerPending = false
    ringCanvas.requestPaint()
  }

  function open(payloadJson) {
    // If already open (e.g. showing a subring), activate the current selection
    // or dismiss.  The second press of the orbit button re-enters via IPC,
    // so we consume it here rather than resetting the ring.
    if (opened) {
      if (selectedIndex >= 0) activateIndex(selectedIndex)
      else dismiss()
      return
    }
    var payload = parseJson(payloadJson || "{}", ({}))
    holdMode = payload.mode !== "click" && payload.hold !== false
    ringId = String(payload.ring || payload.ringId || defaultRingId())
    selectedIndex = -1
    opened = true
    queueCenter(payload)
    Qt.callLater(function() {
      if (!root.opened) return
      root.applyPendingCenter()
      keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    opened = false
    selectedIndex = -1
    centerPending = false
  }

  function dismiss() {
    close()
    if (shell && typeof shell.hide === "function") shell.hide(pluginId)
  }

  function toggle(payloadJson) {
    if (opened) dismiss()
    else open(payloadJson || "{}")
  }

  function release() {
    if (!opened) return "closed"
    if (selectedIndex >= 0) activateIndex(selectedIndex)
    else dismiss()
    return "ok"
  }

  function angleForIndex(index) {
    if (actionCount <= 0) return -Math.PI / 2
    return -Math.PI / 2 + index * (Math.PI * 2 / actionCount)
  }

  function selectedIndexForPoint(px, py) {
    if (actionCount <= 0) return -1
    var dx = px - centerX
    var dy = py - centerY
    var distance = Math.sqrt(dx * dx + dy * dy)
    if (distance < ringInnerRadius || distance > ringOuterRadius + itemSize * 0.8) return -1

    var sector = Math.PI * 2 / actionCount
    var angle = Math.atan2(dy, dx) + Math.PI / 2
    while (angle < 0) angle += Math.PI * 2
    while (angle >= Math.PI * 2) angle -= Math.PI * 2
    return Math.floor((angle + sector / 2) / sector) % actionCount
  }

  function hoverAt(px, py) {
    if (centerPending) return
    lastMouseX = px
    lastMouseY = py
    selectedIndex = selectedIndexForPoint(px, py)
  }

  function selectRelative(delta) {
    if (actionCount <= 0) return
    if (selectedIndex < 0) selectedIndex = 0
    else selectedIndex = (selectedIndex + delta + actionCount) % actionCount
  }

  function activateSelected() {
    var index = selectedIndex
    if (index >= 0) activateIndex(index)
    return index >= 0 ? "ok" : "none"
  }

  function activateIndex(index) {
    if (index < 0 || index >= actionCount) return
    var action = actions[index]
    if (!action) return

    if (action.ring) {
      ringId = String(action.ring)
      selectedIndex = -1
      ringCanvas.requestPaint()
      // Recalculate selection for the new ring at the current cursor position.
      // onEntered won't re-fire after the ring switch (the MouseArea
      // containsMouse is already true), so we compute the slice here so
      // the user sees immediate feedback and can press again to activate.
      if (lastMouseX >= 0 && lastMouseY >= 0) {
        selectedIndex = selectedIndexForPoint(lastMouseX, lastMouseY)
      }
      return
    }

    dismiss()

    if (action.close) return
    if (action.argv && Array.isArray(action.argv) && action.argv.length > 0) {
      var argv = []
      for (var i = 0; i < action.argv.length; i++) argv.push(String(action.argv[i]))
      Qt.callLater(function() { Quickshell.execDetached(argv) })
      return
    }

    var command = String(action.command || "").trim()
    if (command !== "") {
      var cmd = command
      Qt.callLater(function() { Quickshell.execDetached(["bash", "-lc", cmd]) })
    }
  }

  function css(c, alpha) {
    var a = alpha === undefined ? c.a : alpha
    return "rgba(" + Math.round(c.r * 255) + ", " + Math.round(c.g * 255) + ", " + Math.round(c.b * 255) + ", " + a + ")"
  }

  function paintRing(ctx, index, color, widthOffset) {
    if (actionCount <= 0) return
    var sector = Math.PI * 2 / actionCount
    var start = angleForIndex(index) - sector / 2 + 0.035
    var end = angleForIndex(index) + sector / 2 - 0.035
    ctx.beginPath()
    ctx.arc(centerX, centerY, ringMidRadius, start, end, false)
    ctx.strokeStyle = color
    ctx.lineWidth = ringWidth + (widthOffset || 0)
    ctx.lineCap = "round"
    ctx.stroke()
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onLoadFailed: root.loadConfig("")
    onFileChanged: reload()
  }

  Timer {
    interval: 16
    repeat: true
    running: root.opened && root.centerPending
    onTriggered: root.applyPendingCenter()
  }

  IpcHandler {
    target: "local.orbit"
    function open(payloadJson: string): string { root.open(payloadJson); return "ok" }
    function close(): string { root.dismiss(); return "ok" }
    function toggle(payloadJson: string): string { root.toggle(payloadJson); return "ok" }
    function release(): string { return root.release() }
    function activate(): string { return root.activateSelected() }
    function state(): string { return root.opened ? "open" : "closed" }
    function ping(): string { return "ok" }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    onWidthChanged: root.applyPendingCenter()
    onHeightChanged: root.applyPendingCenter()
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "local.orbit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: root.opened ? 1 : 0
    }

    MouseArea {
      id: pointerArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.AllButtons
      cursorShape: root.selectedIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
      onPositionChanged: function(mouse) { root.hoverAt(mouse.x, mouse.y) }
      onPressed: function(mouse) { root.hoverAt(mouse.x, mouse.y) }
      onClicked: function(mouse) {
        root.hoverAt(mouse.x, mouse.y)
        if (!root.holdMode && root.selectedIndex >= 0) root.activateIndex(root.selectedIndex)
        else if (!root.holdMode && root.selectedIndex < 0) root.dismiss()
      }
      onReleased: function(mouse) {
        root.hoverAt(mouse.x, mouse.y)
        if (root.holdMode) root.release()
      }
    }

    Item {
      id: ringCanvas
      anchors.fill: parent
      visible: false
      function requestPaint() {}
    }

    Rectangle {
      id: guideCircle
      width: root.guideRadius * 2
      height: width
      x: root.centerX - width / 2
      y: root.centerY - height / 2
      radius: width / 2
      color: "transparent"
      border.color: root.ringOutline
      border.width: Math.max(1, Style.space(1))
      opacity: root.opened && !root.centerPending ? 1 : 0
    }

    Repeater {
      model: root.actionCount

      Item {
        id: actionItem
        property var action: root.actions[index] || ({})
        property bool selected: index === root.selectedIndex
        readonly property real theta: root.angleForIndex(index)
        readonly property string iconGlyph: action.icon || String(index + 1)
        readonly property var iconBounds: iconMetrics.tightBoundingRect(iconGlyph)

        width: root.itemSize
        height: root.itemSize
        x: root.centerX + Math.cos(theta) * root.guideRadius - width / 2
        y: root.centerY + Math.sin(theta) * root.guideRadius - height / 2
        scale: selected ? 1.08 : 1.0
        opacity: root.opened && !root.centerPending ? 1 : 0

        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: actionItem.selected ? Util.alpha(root.accent, 0.92) : Util.alpha(root.background, 0.94)
          border.color: actionItem.selected ? root.accent : root.border
          border.width: Math.max(1, Style.space(actionItem.selected ? 3 : 2))
        }

        FontMetrics {
          id: iconMetrics
          font.family: root.iconFontFamily
          font.pixelSize: Style.font.display
        }

        Text {
          id: iconText
          text: actionItem.iconGlyph
          color: actionItem.selected ? Color.background : root.foreground
          font.family: root.iconFontFamily
          font.pixelSize: Style.font.display
          maximumLineCount: 1

          // Nerd Font glyphs have uneven bearings. Center the tight glyph
          // bounds, not the font's advance box, so icons sit visually in the
          // middle of the circular buttons.
          x: actionItem.width / 2 - (actionItem.iconBounds.x + actionItem.iconBounds.width / 2)
          y: actionItem.height / 2 - (baselineOffset + actionItem.iconBounds.y + actionItem.iconBounds.height / 2)
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.AllButtons
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            root.selectedIndex = index
            root.lastMouseX = actionItem.x + width / 2
            root.lastMouseY = actionItem.y + height / 2
          }
          onPositionChanged: function(mouse) {
            root.selectedIndex = index
            root.lastMouseX = actionItem.x + mouse.x
            root.lastMouseY = actionItem.y + mouse.y
          }
          onClicked: root.activateIndex(index)
        }
      }
    }

    Rectangle {
      id: centerCard
      width: root.centerSize
      height: root.centerSize
      x: root.centerX - width / 2
      y: root.centerY - height / 2
      radius: width / 2
      color: Util.alpha(root.background, 0.98)
      border.color: root.selectedIndex >= 0 ? root.accent : root.border
      border.width: Math.max(1, Style.space(2))
      opacity: root.opened && !root.centerPending ? 1 : 0

      Text {
        anchors.centerIn: parent
        width: parent.width - Style.space(18)
        text: root.selectedIndex >= 0 ? (root.actions[root.selectedIndex].label || "") : root.ringLabel()
        color: root.selectedIndex >= 0 ? root.accent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismiss()
      }
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          if (root.selectedIndex >= 0) root.activateIndex(root.selectedIndex)
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.text === "l" || event.text === "j") {
          root.selectRelative(1)
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.text === "h" || event.text === "k") {
          root.selectRelative(-1)
          event.accepted = true
          return
        }
        var number = parseInt(event.text, 10)
        if (isFinite(number) && number > 0 && number <= root.actionCount) {
          root.selectedIndex = number - 1
          root.activateIndex(root.selectedIndex)
          event.accepted = true
        }
      }
    }
  }
}
