import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "icyleaf.workspaces"

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

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
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

  GridLayout {
    id: layoutContainer
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : 11
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

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

    // 1..10 Workspaces
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
  }
}
