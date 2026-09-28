import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "services" as Services

Item {
  id: root

  property bool closingFromHost: false
  property var shell: null
  property var manifest: null
  property var settings: ({})

  function syncSettings() {
    var id = (manifest && manifest.id) || "local.manga"
    var config = shell ? shell.shellConfig : null
    var plugins = config ? config.plugins : []
    if (Array.isArray(plugins)) {
      for (var i = 0; i < plugins.length; i++) {
        if (plugins[i] && plugins[i].id === id) {
          settings = plugins[i]
          return
        }
      }
    }
    settings = ({})
  }

  onShellChanged: syncSettings()
  onManifestChanged: syncSettings()
  Component.onCompleted: syncSettings()

  Connections {
    target: shell
    ignoreUnknownSignals: true
    function onShellConfigChanged() {
      root.syncSettings()
    }
  }

  Binding {
    target: Services.Manga
    property: "enableServer"
    value: root.setting("enableServer", true)
  }

  readonly property int configuredWidth: Math.max(560, Number(setting("windowWidth", 580)) || 580)
  readonly property int configuredHeight: Math.max(520, Number(setting("windowHeight", 1045)) || 1045)

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function open(payloadJson) {
    if (!root.setting("enableServer", true)) {
      Quickshell.execDetached(["omarchy-notification-send", "-g", "󰒏", "Manga", "Manga server is off"])
      return
    }
    closingFromHost = false
    window.visible = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "local.manga")
    else
      window.visible = false
  }

  function toggle(payloadJson) {
    if (window.visible) requestClose()
    else open(payloadJson || "{}")
  }

  FloatingWindow {
    id: window
    title: "Manga"
    visible: false
    color: Color.background
    implicitWidth: Style.space(root.configuredWidth)
    implicitHeight: Style.space(root.configuredHeight)
    minimumSize: Qt.size(Style.space(560), Style.space(520))

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide((root.manifest && root.manifest.id) || "local.manga")
      if (visible) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }

    FocusScope {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (mangaReader.handleKey(event)) {
          event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          root.requestClose()
          event.accepted = true
        }
      }

      MangaReader {
        id: mangaReader
        anchors.fill: parent
        onKeyboardFocusRequested: keyCatcher.forceActiveFocus()
      }
    }
  }
}
