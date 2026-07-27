import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "icyleaf.herdr"
  ipcTarget: "icyleaf.herdr"

  property int sessionCount: 0
  property string aggregateStatus: "unknown"
  property bool connected: false
  property string lastError: ""

  readonly property int refreshIntervalMs: 2000
  readonly property color panelFg: bar ? bar.foreground : Color.foreground
  readonly property string panelFont: bar ? bar.fontFamily : Style.font.family
  
  readonly property color widgetColor: {
    if (!connected) return Qt.rgba(panelFg.r, panelFg.g, panelFg.b, 0.62)
    if (aggregateStatus === "needs-input") return Color.urgent
    if (aggregateStatus === "running") return Color.yellow
    if (aggregateStatus === "idle") return Color.accent
    return panelFg
  }

  function statusRank(status) {
    if (status === "needs-input") return 3
    if (status === "running") return 2
    if (status === "idle") return 1
    return 0
  }

  function normalizeStatus(value) {
    var raw = String(value || "").toLowerCase().replace(/[_\s]+/g, "-")
    if (raw === "needs-input" || raw === "blocked" || raw === "waiting-input") return "needs-input"
    if (raw === "running" || raw === "busy") return "running"
    if (raw === "idle") return "idle"
    return "unknown"
  }

  function updateAggregateFromAgents(agents) {
    if (!agents || agents.length === 0) {
      sessionCount = 0
      aggregateStatus = "idle"
      return
    }

    sessionCount = agents.length
    var best = "idle"
    var bestRank = statusRank(best)

    for (var i = 0; i < agents.length; i++) {
      var current = normalizeStatus(agents[i].agent_status)
      var rank = statusRank(current)
      if (rank > bestRank) {
        best = current
        bestRank = rank
      }
    }

    aggregateStatus = best
  }

  function applySnapshotPayload(raw) {
    try {
      var payload = String(raw || "").trim()
      if (payload.length === 0 || payload.charAt(0) !== "{") throw new Error("non-json payload")

      var envelope = JSON.parse(payload)
      if (!envelope || !envelope.result || !envelope.result.snapshot) throw new Error("missing snapshot object")

      var snapshot = envelope.result.snapshot
      if (!Array.isArray(snapshot.agents)) throw new Error("missing agents array")

      var agents = snapshot.agents
      updateAggregateFromAgents(agents)
      connected = true
      lastError = ""
    } catch (error) {
      connected = false
      aggregateStatus = "unknown"
      sessionCount = 0
      lastError = error && error.message ? String(error.message) : "snapshot parse failed"
    }
  }

  function refreshSnapshot() {
    if (!snapshotProc.running) snapshotProc.running = true
  }

  IpcHandler {
    target: root.ipcTarget

    function open() { root.openFromHotkey() }
    function close() { root.close() }
    function show() { root.openFromHotkey() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.refreshSnapshot() }
  }

  Process {
    id: snapshotProc
    command: ["herdr", "api", "snapshot"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySnapshotPayload(text)
    }
  }

  Timer {
    interval: root.refreshIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshSnapshot()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function icon() {
    return "🐚 " + sessionCount
  }

  function tooltip() {
    var lines = []
    lines.push("Herdr Sessions")
    lines.push("Status: " + aggregateStatus)
    lines.push("Sessions: " + sessionCount)
    lines.push("Connected: " + (connected ? "yes" : "no"))
    if (lastError.length > 0) lines.push("Error: " + lastError)
    return lines.join("\n")
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon()
    foreground: root.widgetColor
    tooltipText: root.tooltip()
    onPressed: function(b) { root.toggle() }
  }

  // KeyboardPanel {
  //   id: panel
  //   anchorItem: button
  //   owner: root
  //   bar: root.bar
  //   open: root.opened
  //   focusTarget: keyCatcher
  //   contentWidth: panel.fittedContentWidth(Style.space(380))
  //   contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

  //   // PanelKeyCatcher {
  //   //   id: keyCatcher
  //   //   anchors.fill: parent
  //   //   onCloseRequested: root.close()
  //   //   onTabRequested: function(direction) { root.switchPanel(direction) }

  //   //   Column {
  //   //     id: mainColumn
  //   //     anchors.fill: parent
  //   //     spacing: Style.spacing.md

  //   //     PanelHero {
  //   //       title: "Herdr Sessions"
  //   //       subtitle: "Minimal diagnostic panel"
  //   //       foreground: root.panelFg
  //   //       fontFamily: root.panelFont
  //   //       glyph: "H"
  //   //     }

  //   //     PanelSeparator { foreground: root.panelFg }

  //   //     Row {
  //   //       width: parent.width
  //   //       spacing: Style.spacing.rowGap

  //   //       Text {
  //   //         text: "Widget connected"
  //   //         color: root.panelFg
  //   //         font.family: root.panelFont
  //   //         font.pixelSize: Style.font.body
  //   //       }

  //   //       Item { width: 1; height: 1 }
  //   //     }

  //   //     Text {
  //   //       width: parent.width
  //   //       wrapMode: Text.Wrap
  //   //       text: "Minimal shell loaded. Advanced snapshot rendering is temporarily disabled for debugging."
  //   //       color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.84)
  //   //       font.family: root.panelFont
  //   //       font.pixelSize: Style.font.caption
  //   //     }

  //   //     Text {
  //   //       width: parent.width
  //   //       wrapMode: Text.Wrap
  //   //       text: "If this panel opens, plugin registration works."
  //   //       color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.84)
  //   //       font.family: root.panelFont
  //   //       font.pixelSize: Style.font.caption
  //   //     }
  //   //   }
  //   // }
  // }
}
