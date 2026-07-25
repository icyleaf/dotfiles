import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "icyleaf.workspaces"

  readonly property var activeWindow: root.Window.window
  readonly property var activeScreen: activeWindow ? activeWindow.screen : null
  readonly property string screenName: activeScreen ? activeScreen.name : ""

  function getMonitorId() {
    var name = root.screenName
    if (name === "eDP-1") return 0
    if (name === "DP-1") return 1
    if (name === "DP-2") return 2
    // Fallback if monitors mapping is dynamic
    if (name && name.indexOf("DP-") === 0) {
      var num = parseInt(name.substring(3))
      if (!isNaN(num)) return num
    }
    return 0
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // Workspaces 1 to 9 default + active ones
  function workspaceIds() {
    var monitorId = getMonitorId()
    var offset = monitorId * 10
    var ids = []
    
    // Default workspaces 1 to 9 for this monitor
    for (var j = 1; j <= 9; j++) {
      ids.push(offset + j)
    }

    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > offset && id <= offset + 10 && ids.indexOf(id) === -1) {
        ids.push(id)
      }
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    var monitorId = getMonitorId()
    var offset = monitorId * 10
    var relativeId = id - offset
    root.bar.run("bash /home/icyleaf/.config/hypr/scripts/workspace-switch.sh switch " + relativeId)
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var monitorId: root.getMonitorId()
        readonly property var offset: monitorId * 10
        readonly property var relativeId: modelData - offset

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (relativeId === 10 ? "0" : String(relativeId))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
