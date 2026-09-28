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
    id: labelPill
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Style.space(56)
    width: labelText.implicitWidth + Style.space(32)
    height: labelText.implicitHeight + Style.space(18)
    radius: Style.cornerRadius > 0 ? Style.cornerRadius : 12
    color: Color.background
    border.width: 2
    border.color: Color.accent
    opacity: borderRect.opacity

    Text {
      id: labelText
      anchors.centerIn: parent
      text: root.badge + "  " + root.label + (root.detail !== "" ? "   " + root.detail : "")
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
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
