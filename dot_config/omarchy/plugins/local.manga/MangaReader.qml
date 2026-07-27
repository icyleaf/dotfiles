import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import "colors" as ColorsModule
import "components"
import "services" as Services

Item {
  id: root

  property int tabIndex: 0
  property int browseStack: 0
  property int libraryStack: 0
  property string selectedMangaId: ""

  readonly property var c: ColorsModule.Colors
  readonly property string fontBody: Style.font.family
  signal keyboardFocusRequested()

  function refresh() {
    if (tabIndex === 0) Services.Manga.fetchByOrigin("", true)
    else Services.Manga.fetchDownloads()
  }

  function handleKey(event) {
    var handled = false

    if (tabIndex === 0) {
      if (browseStack === 0) handled = browseView.handleKey(event)
      else if (browseStack === 1) handled = browseDetail.handleKey(event)
      else if (browseStack === 2) handled = browseReader.handleKey(event)
    } else {
      if (libraryStack === 0) handled = libraryView.handleKey(event)
      else if (libraryStack === 1) handled = libraryDetail.handleKey(event)
      else if (libraryStack === 2) handled = libraryReader.handleKey(event)
    }

    if (handled) return true

    if (event.key === Qt.Key_1) {
      tabIndex = 0
      requestKeyboardFocus()
      return true
    }
    if (event.key === Qt.Key_2) {
      tabIndex = 1
      requestKeyboardFocus()
      return true
    }

    return false
  }

  function requestKeyboardFocus() {
    keyboardFocusRequested()
  }

  Rectangle {
    anchors.fill: parent
    color: c.background
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Rectangle {
      Layout.fillWidth: true
      height: 44
      color: c.surface_container_low
      z: 10

      Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 1
        color: c.outline_variant
        opacity: 0.4
      }

      Row {
        anchors.fill: parent

        Repeater {
          model: [
            { label: "Browse", icon: "⌕" },
            { label: "Library", icon: "▣" }
          ]

          delegate: Item {
            width: root.width / 2
            height: parent.height

            readonly property bool active: root.tabIndex === index

            Rectangle {
              anchors.fill: parent
              color: tabArea.containsMouse && !active
                ? Qt.rgba(c.primary.r, c.primary.g, c.primary.b, 0.08)
                : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }
            }

            Column {
              anchors.centerIn: parent
              spacing: 1

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.icon
                font.pixelSize: 13
                color: active ? c.primary : c.on_surface_variant
                opacity: active ? 1 : 0.6
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                font.family: root.fontBody
                font.pixelSize: 10
                color: active ? c.primary : c.on_surface_variant
                opacity: active ? 1 : 0.6
              }
            }

            Rectangle {
              anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
              }
              width: active ? 28 : 0
              height: 2
              radius: 1
              color: c.primary
              Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            MouseArea {
              id: tabArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                root.tabIndex = index
                root.requestKeyboardFocus()
              }
            }
          }
        }
      }
    }

    StackLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      currentIndex: root.tabIndex

      Item {
        BrowseView {
          id: browseView
          anchors.fill: parent
          visible: root.browseStack === 0
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onMangaSelected: function(mangaId) {
            root.selectedMangaId = mangaId
            root.browseStack = 1
            root.requestKeyboardFocus()
          }
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }

        DetailView {
          id: browseDetail
          anchors.fill: parent
          visible: root.browseStack === 1
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onBackRequested: root.browseStack = 0
          onChapterSelected: root.browseStack = 2
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }

        ReaderView {
          id: browseReader
          anchors.fill: parent
          visible: root.browseStack === 2
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onBackRequested: {
            root.browseStack = 1
            browseReader.reset()
            root.requestKeyboardFocus()
          }
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }
      }

      Item {
        LibraryView {
          id: libraryView
          anchors.fill: parent
          visible: root.libraryStack === 0
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onMangaSelected: function(mangaId) {
            root.selectedMangaId = mangaId
            root.libraryStack = 1
            root.requestKeyboardFocus()
          }
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }

        DetailView {
          id: libraryDetail
          anchors.fill: parent
          visible: root.libraryStack === 1
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onBackRequested: root.libraryStack = 0
          onChapterSelected: root.libraryStack = 2
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }

        ReaderView {
          id: libraryReader
          anchors.fill: parent
          visible: root.libraryStack === 2
          opacity: visible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          onBackRequested: {
            root.libraryStack = 1
            libraryReader.reset()
            root.requestKeyboardFocus()
          }
          onKeyboardFocusRequested: root.requestKeyboardFocus()
        }
      }
    }
  }
}
