import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Full-screen, click-through overlay that briefly outlines one monitor and
// shows its identity. The Workspace Bindings monitor picker uses it to reveal
// which physical display each option refers to. It never accepts input (empty
// mask), so the menu underneath stays fully usable while it is on screen.
PanelWindow {
  id: root

  property string badge: ""
  property string label: ""
  property string detail: ""
  property int flashMs: 2600

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  visible: borderRect.opacity > 0.001
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "icyleaf.workspaces.monitor-flash"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  function flash(durationMs) {
    if (durationMs > 0) root.flashMs = durationMs
    pulseAnimation.restart()
    hideTimer.restart()
  }

  Rectangle {
    id: borderRect
    anchors.fill: parent
    color: "transparent"
    border.width: Style.space(5)
    border.color: Color.accent
    opacity: 0
  }

  Rectangle {
    id: identityCard
    anchors.centerIn: parent
    width: identityColumn.implicitWidth + Style.space(56)
    height: identityColumn.implicitHeight + Style.space(44)
    radius: Style.cornerRadius > 0 ? Style.cornerRadius : 16
    color: Color.background
    border.width: 3
    border.color: Color.accent
    opacity: borderRect.opacity

    Column {
      id: identityColumn
      anchors.centerIn: parent
      spacing: Style.space(8)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.badge
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.displayLarge
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.detail !== ""
        text: root.detail
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }
  }

  SequentialAnimation {
    id: pulseAnimation
    NumberAnimation { target: borderRect; property: "opacity"; from: 0; to: 1; duration: 160 }
    NumberAnimation { target: borderRect; property: "opacity"; to: 1; duration: 520 }
    NumberAnimation { target: borderRect; property: "opacity"; to: 0.25; duration: 320 }
    NumberAnimation { target: borderRect; property: "opacity"; to: 1; duration: 320 }
    NumberAnimation { target: borderRect; property: "opacity"; to: 0.25; duration: 320 }
    NumberAnimation { target: borderRect; property: "opacity"; to: 1; duration: 320 }
  }

  Timer {
    id: hideTimer
    interval: root.flashMs
    onTriggered: fadeOut.start()
  }

  NumberAnimation {
    id: fadeOut
    target: borderRect
    property: "opacity"
    to: 0
    duration: 220
  }
}
