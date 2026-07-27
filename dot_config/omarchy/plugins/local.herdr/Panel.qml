import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "local.herdr"
  ipcTarget: "local.herdr"

  readonly property string badgeText: String(setting("badgeText", "0") || "0")
  readonly property color panelFg: bar ? bar.foreground : Color.foreground
  readonly property string panelFont: bar ? bar.fontFamily : Style.font.family

  IpcHandler {
    target: root.ipcTarget

    function open() { root.openFromHotkey() }
    function close() { root.close() }
    function show() { root.openFromHotkey() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "HRD " + root.badgeText
    horizontalMargin: 7
    verticalPadding: 7
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: mainColumn
        anchors.fill: parent
        spacing: Style.spacing.md

        PanelHero {
          title: "Herdr Sessions"
          subtitle: "Overview shell ready"
          foreground: root.panelFg
          fontFamily: root.panelFont
          glyph: "H"
        }

        PanelSeparator { foreground: root.panelFg }

        Row {
          width: parent.width
          spacing: Style.spacing.rowGap

          Text {
            text: "Widget connected"
            color: root.panelFg
            font.family: root.panelFont
            font.pixelSize: Style.font.body
          }

          Item { width: 1; height: 1 }
        }

        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: "Herdr overview shell is active. Live session data will appear in upcoming tickets."
          color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.84)
          font.family: root.panelFont
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
