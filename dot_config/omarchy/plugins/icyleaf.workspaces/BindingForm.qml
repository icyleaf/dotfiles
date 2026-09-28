import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Modal editor for one Workspace Binding: app class, optional title regex,
// target monitor, workspace slot and whether focus follows. Summoned by the
// plugin's `editBinding` IPC; the QML shell owns presentation only, saving is
// delegated back to the shell (which runs the helper).
PanelWindow {
  id: root

  property bool formOpen: false
  property var monitorOptions: [] // [{ value: "desc:...", label: "M1 · DP-1" }]
  property var initial: ({})

  signal saveRequested(var result)
  signal cancelRequested()

  property string classText: ""
  property string titleText: ""
  property string monitorValue: ""
  property string workspaceValue: "1"
  property string openValue: "silent"

  function openForm(data) {
    root.classText = String(data.class || "")
    root.titleText = String(data.title || "")
    root.monitorValue = String(data.monitor || (root.monitorOptions.length > 0 ? root.monitorOptions[0].value : ""))
    root.workspaceValue = String(data.slot || 1)
    root.openValue = data.focus === true ? "switch" : "silent"
    root.formOpen = true
    classField.forceActiveFocus()
  }

  function closeForm() {
    root.formOpen = false
  }

  function canSave() {
    return root.classText.trim() !== "" && root.monitorValue !== ""
  }

  function submit() {
    if (!root.canSave()) return
    root.saveRequested({
      class: root.classText.trim(),
      title: root.titleText.trim(),
      monitor: root.monitorValue,
      slot: parseInt(root.workspaceValue),
      focus: root.openValue === "switch"
    })
  }

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  visible: root.formOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "icyleaf.workspaces.binding-form"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.formOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.55)

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancelRequested()
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Style.space(600)
    implicitHeight: content.implicitHeight + Style.space(40)
    radius: Style.cornerRadius > 0 ? Style.cornerRadius : 14
    color: Color.popups.background
    border.width: 1
    border.color: Util.alpha(Color.foreground, 0.15)

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        root.cancelRequested()
        event.accepted = true
      }
    }

    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: Style.space(20)
      spacing: Style.space(14)

      Text {
        Layout.fillWidth: true
        text: "󰍹  WORKSPACE BINDING"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
        font.letterSpacing: 1.2
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
          text: "App class (regex)"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        TextField {
          id: classField
          Layout.fillWidth: true
          text: root.classText
          placeholderText: "e.g. ^wechat$"
          onTextEdited: root.classText = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
          text: "Window title regex (optional)"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        TextField {
          Layout.fillWidth: true
          text: root.titleText
          placeholderText: "leave empty to match by class only"
          onTextEdited: root.titleText = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
          text: "Monitor"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Repeater {
            model: root.monitorOptions

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: rowColumn.implicitHeight + Style.space(20)
              radius: Style.cornerRadius > 0 ? Style.cornerRadius : 8
              color: root.monitorValue === modelData.value
                ? Util.alpha(Color.accent, 0.18)
                : Util.alpha(Color.foreground, 0.04)
              border.width: 1
              border.color: root.monitorValue === modelData.value
                ? Color.accent
                : Util.alpha(Color.foreground, 0.12)

              Column {
                id: rowColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                anchors.topMargin: Style.space(10)
                spacing: 2

                Text {
                  width: parent.width
                  text: modelData.label
                  color: Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.description
                  color: Color.muted
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: root.monitorValue = modelData.value
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
          text: "Workspace"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        ButtonGroup {
          Layout.fillWidth: true
          options: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
          value: root.workspaceValue
          onChanged: function(newValue) { root.workspaceValue = newValue }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
          text: "Open"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        ButtonGroup {
          Layout.fillWidth: true
          options: [
            { value: "silent", label: "Silent" },
            { value: "switch", label: "Switch focus" }
          ]
          value: root.openValue
          onChanged: function(newValue) { root.openValue = newValue }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(6)
        spacing: Style.space(10)

        Item { Layout.fillWidth: true }

        Button {
          text: "Cancel"
          bordered: true
          onClicked: root.cancelRequested()
        }

        Button {
          text: "Save"
          selected: true
          enabled: root.canSave()
          onClicked: root.submit()
        }
      }
    }
  }
}
