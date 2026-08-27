import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "icyleaf.workspaces"

  // -------------------------------------------------------------- Special Workspaces Configuration
  readonly property var defaultSpecials: [
    { name: "silent", icon: "󰏤", label: "silent" },
    { name: "term", icon: "", label: "term" },
    { name: "chat", icon: "󰭹", label: "chat" },
    { name: "music", icon: "󰎆", label: "music" }
  ]

  readonly property var specialsList: {
    var custom = root.setting("specials", null)
    if (Array.isArray(custom) && custom.length > 0) {
      var iconMap = { silent: "󰏤", term: "", chat: "󰭹", music: "󰎆", scratch: "󰘳", notes: "󰠮" }
      return custom.map(function(item) {
        if (typeof item === "string") {
          return { name: item, icon: iconMap[item] || "󰘳", label: item }
        }
        return item
      })
    }
    return defaultSpecials
  }

  readonly property string specialDisplayMode: String(root.setting("specialDisplayMode", "primaryOnly"))
  readonly property bool isPrimaryMonitor: root.monitorId === 0
  readonly property bool shouldShowSpecials: {
    if (root.specialDisplayMode === "none") return false
    if (root.specialDisplayMode === "primaryOnly") return root.isPrimaryMonitor
    return true // "allAlways" or "allWhenOccupied"
  }

  property bool specialMenuOpen: false

  onSpecialMenuOpenChanged: {
    if (specialMenuOpen) {
      pickerFocusTimer.restart()
    }
  }

  Timer {
    id: pickerFocusTimer
    interval: 50
    onTriggered: {
      if (pickerCard) pickerCard.forceActiveFocus()
    }
  }

  function openSpecialMenu() {
    root.specialMenuOpen = true
  }

  function closeSpecialMenu() {
    root.specialMenuOpen = false
  }

  function toggleSpecialMenu() {
    root.specialMenuOpen = !root.specialMenuOpen
  }

  function getDigitIndex(event) {
    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
      return event.key - Qt.Key_1
    }
    var shiftKeys = [
      Qt.Key_Exclam,      // 1 -> !
      Qt.Key_At,          // 2 -> @
      Qt.Key_NumberSign,  // 3 -> #
      Qt.Key_Dollar,      // 4 -> $
      Qt.Key_Percent,     // 5 -> %
      Qt.Key_AsciiCircum, // 6 -> ^
      Qt.Key_Ampersand,   // 7 -> &
      Qt.Key_Asterisk,    // 8 -> *
      Qt.Key_ParenLeft    // 9 -> (
    ]
    var sIdx = shiftKeys.indexOf(event.key)
    if (sIdx !== -1) return sIdx

    var ch = String(event.text || "")
    if (ch >= "1" && ch <= "9") return parseInt(ch, 10) - 1
    var syms = "!@#$%^&*("
    var symIdx = syms.indexOf(ch)
    if (symIdx !== -1) return symIdx

    return -1
  }

  // -------------------------------------------------------------- IPC Handler
  IpcHandler {
    target: "icyleaf.workspaces"

    function focus(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.focusActiveMonitorWorkspace(slot)
      return "ok"
    }

    function move(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.moveActiveMonitorWindow(slot, true)
      return "ok"
    }

    function movesilent(slotStr: string): string {
      var slot = parseInt(String(slotStr), 10)
      if (isNaN(slot)) return "invalid slot"
      root.moveActiveMonitorWindow(slot, false)
      return "ok"
    }

    function toggleSpecial(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.toggleSpecial(name)
      return "ok"
    }

    function moveSpecial(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.moveSpecial(name, false)
      return "ok"
    }

    function moveSpecialFollow(nameStr: string): string {
      var name = String(nameStr || "").trim()
      if (name === "") return "invalid name"
      root.moveSpecial(name, true)
      return "ok"
    }

    function selectSpecial(): string {
      root.toggleSpecialMenu()
      return "ok"
    }

    function toggleSpecialMenu(): string {
      root.toggleSpecialMenu()
      return "ok"
    }
  }

  // -------------------------------------------------------------- monitor anchor
  readonly property var barWindow: root.QsWindow ? root.QsWindow.window : null
  readonly property var monitor: barWindow && barWindow.screen ? Hyprland.monitorFor(barWindow.screen) : null
  readonly property int monitorId: monitor !== null && monitor.id !== undefined ? monitor.id : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.id : 0)
  readonly property string monitorName: monitor ? String(monitor.name || "") : ""
  readonly property string monitorDesc: monitor ? String(monitor.description || "") : ""
  readonly property bool isFocusedMonitor: monitor !== null && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.id === monitor.id

  readonly property int offset: monitorId * 10
  readonly property string monitorBadgeText: "󰍹 M" + (monitorId + 1)
  readonly property string monitorTooltip: {
    var desc = monitorDesc ? (monitorDesc + (monitorName ? " (" + monitorName + ")" : "")) : (monitorName ? monitorName : ("Monitor " + (monitorId + 1)))
    return desc + (isFocusedMonitor ? " · [Focused]" : "")
  }

  // Active Special Workspace on this monitor
  readonly property var activeSpecialWs: root.monitor ? root.monitor.specialWorkspace : null
  readonly property string activeSpecialName: {
    if (!activeSpecialWs) return ""
    var n = String(activeSpecialWs.name || "")
    if (n.indexOf("special:") === 0) return n.substring(8)
    return n
  }
  readonly property bool hasActiveSpecial: activeSpecialName !== ""

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function specialWorkspaceByName(name) {
    var targetName = "special:" + name
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (String(values[i].name) === targetName) return values[i]
    }
    return null
  }

  function isSpecialActive(name) {
    var targetName = "special:" + name
    if (root.monitor && root.monitor.specialWorkspace) {
      return String(root.monitor.specialWorkspace.name) === targetName
    }
    return false
  }

  // -------------------------------------------------------------- actions & ipc
  function quoteLua(value) {
    return "\"" + String(value)
      .replace(/\\/g, "\\\\")
      .replace(/"/g, "\\\"")
      .replace(/\n/g, "\\n")
      .replace(/\r/g, "\\r")
      + "\""
  }

  function runLua(body) {
    Hyprland.dispatch("function() " + body + " end")
  }

  function focusMonitor() {
    if (!root.monitorName) return
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(root.monitorName) + " }))")
  }

  function focusWorkspace(slot) {
    var wsId = root.offset + slot
    if (!root.monitorName) {
      root.runLua("hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }))")
      return
    }
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }));")
  }

  function moveWindowTo(slot) {
    var wsId = root.offset + slot
    if (!root.monitorName) return
    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(root.monitorName) + " })); "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua(String(wsId)) + ", window = \"address:\" .. w.address, follow = false }));")
  }

  function focusActiveMonitorWorkspace(slot) {
    var mon = Hyprland.focusedMonitor
    if (!mon) return
    var monName = String(mon.name || "")
    var monId = mon.id !== undefined ? mon.id : 0
    var wsId = monId * 10 + slot

    if (monName === "") {
      root.runLua("hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }))")
      return
    }
    root.runLua("hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua(String(wsId)) + " }));")
  }

  function moveActiveMonitorWindow(slot, follow) {
    var mon = Hyprland.focusedMonitor
    if (!mon) return
    var monName = String(mon.name || "")
    var monId = mon.id !== undefined ? mon.id : 0
    var wsId = monId * 10 + slot

    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.workspace.move({ workspace = " + root.quoteLua(String(wsId)) + ", monitor = " + root.quoteLua(monName) + " })); "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua(String(wsId)) + ", window = \"address:\" .. w.address, follow = " + (follow ? "true" : "false") + " }));")
  }

  function toggleSpecial(name) {
    root.runLua("hl.dispatch(hl.dsp.workspace.toggle_special(" + root.quoteLua(name) + "))")
  }

  function moveSpecial(name, follow) {
    root.runLua("local w = hl.get_active_window(); if not w then return end; "
      + "hl.dispatch(hl.dsp.window.move({ workspace = " + root.quoteLua("special:" + name)
      + ", window = \"address:\" .. w.address, follow = " + (follow ? "true" : "false") + " }));")
  }

  // -------------------------------------------------------------- wheel cycling
  property real wheelAccumulator: 0

  function cycleBy(step) {
    var currentSlot = 1
    if (root.monitor && root.monitor.activeWorkspace) {
      var activeId = root.monitor.activeWorkspace.id
      var rel = activeId - root.offset
      if (rel >= 1 && rel <= 10) currentSlot = rel
    }
    var nextSlot = ((currentSlot - 1 + step) % 10 + 10) % 10 + 1
    root.focusWorkspace(nextSlot)
  }

  function onWheel(delta) {
    var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
    root.wheelAccumulator = wheel.remainder
    if (wheel.steps !== 0) root.cycleBy(wheel.steps > 0 ? -1 : 1)
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: layoutContainer.implicitWidth + trailingGap
  implicitHeight: layoutContainer.implicitHeight

  RowLayout {
    id: layoutContainer
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    spacing: Style.space(1)

    // Monitor Badge Pill
    WidgetButton {
      bar: root.bar
      text: root.monitorBadgeText
      useActiveColor: false
      tooltipText: root.monitorTooltip
      opacity: root.isFocusedMonitor ? 1.0 : 0.5
      horizontalMargin: 6
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : Style.space(34)
      fixedHeight: root.barSize
      onPressed: function() { root.focusMonitor() }
      onWheelMoved: function(delta) { root.onWheel(delta) }
    }

    // 1..10 Regular Workspaces
    Repeater {
      model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      WidgetButton {
        required property int modelData

        readonly property int wsId: root.offset + modelData
        readonly property var workspace: root.workspaceById(wsId)
        readonly property bool occupied: workspace !== null && workspace.toplevels && workspace.toplevels.values.length > 0
        readonly property bool activeOnMonitor: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === wsId
        readonly property bool focusedGlobally: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId

        bar: root.bar
        text: (activeOnMonitor || focusedGlobally) ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        useActiveColor: false
        tooltipText: "Workspace " + wsId + " (Slot " + (modelData === 10 ? 0 : modelData) + ")"
        opacity: activeOnMonitor || focusedGlobally || occupied ? 1.0 : 0.4
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function(button) {
          if (button === Qt.RightButton) {
            root.moveWindowTo(modelData)
          } else {
            root.focusWorkspace(modelData)
          }
        }
        onWheelMoved: function(delta) { root.onWheel(delta) }
      }
    }

    // Active Special Workspace Indicator Pill (Visible whenever a special workspace is open on this screen)
    WidgetButton {
      visible: root.hasActiveSpecial
      bar: root.bar
      text: "󰘳 " + root.activeSpecialName
      useActiveColor: false
      tooltipText: "Active Special Workspace: " + root.activeSpecialName + " (Click to toggle/close)"
      opacity: 1.0
      horizontalMargin: 6
      verticalPadding: 6
      fixedHeight: root.barSize
      onPressed: function() { root.toggleSpecial(root.activeSpecialName) }
    }

    // Separator before Specials
    Rectangle {
      visible: (root.shouldShowSpecials && root.specialsList.length > 0) || root.hasActiveSpecial
      implicitWidth: root.vertical ? (root.barSize - Style.space(8)) : 1
      implicitHeight: root.vertical ? 1 : Style.space(12)
      Layout.alignment: Qt.AlignVCenter
      color: Util.alpha(root.bar ? root.bar.barForeground : Color.foreground, 0.2)
    }

    // Special Workspaces (Scratchpads)
    Repeater {
      model: root.shouldShowSpecials ? root.specialsList : []

      WidgetButton {
        required property var modelData

        readonly property string specialName: String(modelData.name || "")
        readonly property string specialIcon: String(modelData.icon || "󰘳")
        readonly property var ws: root.specialWorkspaceByName(specialName)
        readonly property bool occupied: ws !== null && ws.toplevels && ws.toplevels.values.length > 0
        readonly property bool activeOnScreen: root.isSpecialActive(specialName)

        visible: {
          if (root.specialDisplayMode === "allWhenOccupied" && !root.isPrimaryMonitor) {
            return occupied || activeOnScreen
          }
          return true
        }

        bar: root.bar
        text: activeOnScreen ? (specialIcon + " " + specialName) : specialIcon
        useActiveColor: false
        tooltipText: "Special: " + specialName + (activeOnScreen ? " [Active]" : (occupied ? " (" + ws.toplevels.values.length + " windows)" : " [Empty]"))
        opacity: activeOnScreen ? 1.0 : (occupied ? 0.85 : 0.35)
        horizontalMargin: activeOnScreen ? 6 : 4
        verticalPadding: 6
        fixedWidth: activeOnScreen ? -1 : (root.vertical ? root.barSize : Style.space(20))
        fixedHeight: root.barSize
        onPressed: function(button) {
          if (button === Qt.RightButton) {
            root.moveSpecial(specialName, false)
          } else {
            root.toggleSpecial(specialName)
          }
        }
      }
    }
  }

  // -------------------------------------------------------------- Quick Picker Overlay (SUPER + ALT + S)
  PanelWindow {
    id: specialPickerWindow
    visible: root.specialMenuOpen && root.isPrimaryMonitor
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "icyleaf.workspaces.picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.specialMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.background, 0.55)
      opacity: root.specialMenuOpen ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeSpecialMenu()
      }

      Rectangle {
        id: pickerCard
        anchors.centerIn: parent
        width: Style.space(380)
        implicitHeight: pickerContent.implicitHeight + Style.space(32)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 12
        color: Color.surface || Color.background
        border.width: 1
        border.color: Util.alpha(Color.foreground, 0.18)
        focus: root.specialMenuOpen

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.closeSpecialMenu()
            event.accepted = true
            return
          }
          var digitIdx = root.getDigitIndex(event)
          if (digitIdx >= 0 && digitIdx < root.specialsList.length) {
            var item = root.specialsList[digitIdx]
            var specialName = String(item.name || "")
            if (event.modifiers & Qt.ShiftModifier) {
              root.moveSpecial(specialName, false)
            } else {
              root.toggleSpecial(specialName)
            }
            root.closeSpecialMenu()
            event.accepted = true
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) {}
        }

        ColumnLayout {
          id: pickerContent
          anchors.fill: parent
          anchors.margins: Style.space(16)
          spacing: Style.space(12)

          // Header
          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "󰘳  SPECIAL SCRATCHPADS"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              color: Util.alpha(Color.foreground, 0.6)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "Esc to close"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.4)
            }
          }

          // Specials List
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Repeater {
              model: root.specialsList

              Rectangle {
                required property var modelData
                required property int index

                readonly property string spName: String(modelData.name || "")
                readonly property string spIcon: String(modelData.icon || "󰘳")
                readonly property var spWs: root.specialWorkspaceByName(spName)
                readonly property int winCount: (spWs && spWs.toplevels) ? spWs.toplevels.values.length : 0
                readonly property bool isActive: root.isSpecialActive(spName)
                readonly property bool isHovered: itemMouse.containsMouse

                Layout.fillWidth: true
                implicitHeight: Style.space(38)
                radius: 8
                color: isActive ? Util.alpha(Color.foreground, 0.12) : (isHovered ? Util.alpha(Color.foreground, 0.06) : "transparent")
                border.width: isActive ? 1 : 0
                border.color: Util.alpha(Color.foreground, 0.25)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(10)

                  // Number badge [1]
                  Rectangle {
                    implicitWidth: Style.space(22)
                    implicitHeight: Style.space(22)
                    radius: 4
                    color: Util.alpha(Color.foreground, 0.08)
                    border.width: 1
                    border.color: Util.alpha(Color.foreground, 0.15)
                    Text {
                      anchors.centerIn: parent
                      text: String(index + 1)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                      color: Color.foreground
                    }
                  }

                  // Icon
                  Text {
                    text: spIcon
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    color: Color.foreground
                  }

                  // Name
                  Text {
                    text: spName
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: Color.foreground
                  }

                  Item { Layout.fillWidth: true }

                  // Status
                  Text {
                    text: isActive ? "Active" : (winCount > 0 ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: isActive ? Color.foreground : Util.alpha(Color.foreground, 0.5)
                  }
                }

                MouseArea {
                  id: itemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      root.moveSpecial(spName, false)
                    } else {
                      root.toggleSpecial(spName)
                    }
                    root.closeSpecialMenu()
                  }
                }
              }
            }
          }

          // Footer
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Util.alpha(Color.foreground, 0.1)
          }

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "⌨ 1-4 Switch · Shift+1-4 Move"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.45)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "🖱 Left: Toggle · Right: Move"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Util.alpha(Color.foreground, 0.45)
            }
          }
        }
      }
    }
  }
}
