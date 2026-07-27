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
  property var sessionRows: ([])
  property int disconnectCount: 0

  readonly property int retentionWindowMs: settings && settings.retentionWindowMs !== undefined ? Number(settings.retentionWindowMs) : 6000
  readonly property string promptDensity: settings && settings.promptDensity !== undefined ? String(settings.promptDensity) : "compact"
  readonly property string herdrLaunchCmd: "omarchy-launch-terminal bash -c 'herdr'"

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

  function statusText(status) {
    if (status === "needs-input") return "needs input"
    if (status === "running") return "running"
    if (status === "idle") return "idle"
    return "unknown"
  }

  function statusColor(status) {
    if (status === "needs-input") return Color.urgent
    if (status === "running") return Color.yellow
    if (status === "idle") return Color.accent
    return Qt.rgba(panelFg.r, panelFg.g, panelFg.b, 0.75)
  }

  function normalizeStatus(value) {
    var raw = String(value || "").toLowerCase().replace(/[_\s]+/g, "-")
    if (raw === "needs-input" || raw === "blocked" || raw === "waiting-input") return "needs-input"
    if (raw === "running" || raw === "busy") return "running"
    if (raw === "idle") return "idle"
    return "unknown"
  }

  function firstString(values) {
    for (var i = 0; i < values.length; i++) {
      var value = values[i]
      if (value === undefined || value === null) continue
      var text = String(value).trim()
      if (text.length > 0) return text
    }
    return ""
  }

  function truncateText(text, limit) {
    if (text.length <= limit) return text
    return text.slice(0, limit - 3) + "..."
  }

  function normalizePrompt(text) {
    var compact = String(text || "").replace(/\s+/g, " ").trim()
    if (compact.length === 0) return "No prompt available."
    var limit = promptDensity === "expanded" ? 144 : 72
    return truncateText(compact, limit)
  }

  function parseTimestampMs(value) {
    if (value === undefined || value === null) return -1

    if (typeof value === "number") {
      if (!isFinite(value) || value <= 0) return -1
      if (value >= 1000000000000) return Math.round(value)
      if (value >= 1000000000) return Math.round(value * 1000)
      return Math.round(value)
    }

    var parsed = Date.parse(String(value))
    return isNaN(parsed) ? -1 : parsed
  }

  function formatDurationMs(durationMs) {
    if (!isFinite(durationMs) || durationMs < 0) return "n/a"
    if (durationMs < 60000) return Math.floor(durationMs / 1000) + "s"
    if (durationMs < 3600000) return Math.floor(durationMs / 60000) + "m"
    if (durationMs < 86400000) return Math.floor(durationMs / 3600000) + "h"
    return Math.floor(durationMs / 86400000) + "d"
  }

  function formatElapsed(startMs) {
    if (startMs < 0) return "n/a"
    return formatDurationMs(Math.max(0, Date.now() - startMs))
  }

  function formatReadAgo(readMs) {
    if (readMs < 0) return "n/a"
    return formatDurationMs(Math.max(0, Date.now() - readMs)) + " ago"
  }

  function buildSessionRows(agents) {
    var rows = []
    for (var i = 0; i < agents.length; i++) {
      var agent = agents[i] || {}
      var meta = agent.metadata || {}
      var status = normalizeStatus(agent.agent_status)

      var promptRaw = firstString([
        agent.prompt,
        agent.last_prompt,
        agent.current_prompt,
        meta.prompt,
        meta.last_prompt,
        meta.current_prompt,
        agent.terminal_title_stripped,
        agent.terminal_title
      ])

      var startMs = parseTimestampMs(firstString([
        agent.started_at,
        agent.created_at,
        meta.started_at,
        meta.created_at
      ]))

      var readMs = parseTimestampMs(firstString([
        agent.last_read_at,
        agent.read_at,
        meta.last_read_at,
        meta.read_at,
        agent.updated_at,
        meta.updated_at
      ]))

      var recency = Number(agent.state_change_seq)
      if (!isFinite(recency)) recency = Number(agent.revision)
      if (!isFinite(recency)) recency = 0

      var title = firstString([agent.agent, agent.terminal_title_stripped, agent.pane_id, "session"])

      rows.push({
        id: firstString([agent.agent, agent.pane_id, agent.terminal_id, "session-" + i]),
        title: title,
        agentName: firstString([agent.agent]),
        status: status,
        statusText: statusText(status),
        statusColor: statusColor(status),
        promptSnippet: normalizePrompt(promptRaw),
        elapsedText: formatElapsed(startMs),
        readAgoText: formatReadAgo(readMs),
        recency: recency
      })
    }

    rows.sort(function(a, b) {
      var rankDelta = statusRank(b.status) - statusRank(a.status)
      if (rankDelta !== 0) return rankDelta

      var recencyDelta = b.recency - a.recency
      if (recencyDelta !== 0) return recencyDelta

      if (a.title < b.title) return -1
      if (a.title > b.title) return 1
      return 0
    })

    return rows
  }

  function updateAggregateFromRows(rows) {
    if (!rows || rows.length === 0) {
      sessionCount = 0
      aggregateStatus = "idle"
      sessionRows = []
      return
    }

    sessionRows = rows
    sessionCount = rows.length
    var best = "idle"
    var bestRank = statusRank(best)

    for (var i = 0; i < rows.length; i++) {
      var current = rows[i].status
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

      var rows = buildSessionRows(snapshot.agents)
      updateAggregateFromRows(rows)
      connected = true
      lastError = ""
      disconnectCount = 0
    } catch (error) {
      connected = false
      lastError = error && error.message ? String(error.message) : "snapshot parse failed"
      disconnectCount++
      if (disconnectCount * refreshIntervalMs >= retentionWindowMs) {
        aggregateStatus = "unknown"
        sessionCount = 0
        sessionRows = []
      }
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

  Process {
    id: jumpProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
    }
  }

  function jumpToAgent(agentName) {
    if (!agentName) {
      jumpProc.command = [
        "omarchy-notification-send",
        "-u", "critical",
        "-g", "⚠️",
        "Jump Failed",
        "No agent name provided for this session."
      ]
      jumpProc.running = true
      return
    }
    jumpProc.command = [
      "bash", "-c",
      "if ! command -v hyprctl &>/dev/null; then\n" +
      "  omarchy-notification-send -u critical -g \"⚠️\" \"Jump Failed\" \"Window jumping is only supported under Hyprland.\"\n" +
      "  exit 1\n" +
      "fi\n" +
      "agent=\"$1\"\n" +
      "address=$(hyprctl clients -j 2>/dev/null | jq -r --arg p \"$agent\" '[.[] | select(((.class // \"\") | ascii_downcase | contains($p | ascii_downcase)) or ((.title // \"\") | ascii_downcase | contains($p | ascii_downcase)))] | first.address // empty')\n" +
      "if [[ -n \"$address\" ]]; then\n" +
      "  hyprctl dispatch focuswindow \"address:$address\" >/dev/null\n" +
      "  exit 0\n" +
      "else\n" +
      "  omarchy-notification-send -u critical -g \"⚠️\" \"Jump Failed\" \"No active window found for agent '$agent'\"\n" +
      "  exit 1\n" +
      "fi",
      "--",
      agentName
    ]
    jumpProc.running = true
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
          meta: root.sessionCount + " sessions - " + root.statusText(root.aggregateStatus)
          foreground: root.panelFg
          fontFamily: root.panelFont
          iconComponent: Text {
            text: "🐚"
            font.family: root.panelFont
            font.pixelSize: Style.font.display
            color: root.panelFg
          }
        }

        PanelSeparator { foreground: root.panelFg }

        Row {
          width: parent.width
          spacing: Style.spacing.rowGap

          Text {
            width: parent.width - (openHerdrButton.visible ? openHerdrButton.width + parent.spacing : 0)
            wrapMode: Text.Wrap
            text: connected
              ? "Snapshot stream active via herdr api snapshot."
              : "Snapshot disconnected. Open Herdr to re-establish updates."
            color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.84)
            font.family: root.panelFont
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }

          Button {
            id: openHerdrButton
            visible: !connected
            text: "Open Herdr"
            bordered: true
            focusable: true
            foreground: root.panelFg
            fontFamily: root.panelFont
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
              if (root.bar) {
                root.bar.run(root.herdrLaunchCmd)
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.sm

          Repeater {
            model: root.sessionRows

            delegate: Rectangle {
              required property var modelData

              width: parent ? parent.width : 0
              radius: Style.cornerRadius
              color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.06)
              border.width: 1
              border.color: Qt.rgba(modelData.statusColor.r, modelData.statusColor.g, modelData.statusColor.b, 0.38)
              implicitHeight: rowContentRow.implicitHeight + Style.spacing.sm * 2

              Row {
                id: rowContentRow
                anchors.fill: parent
                anchors.margins: Style.spacing.sm
                spacing: Style.spacing.sm

                Column {
                  id: rowColumn
                  width: parent.width - (jumpButton.visible ? jumpButton.width + parent.spacing : 0)
                  spacing: Style.spacing.xs

                  Row {
                    width: parent.width
                    spacing: Style.spacing.rowGap

                    Text {
                      text: modelData.title
                      color: root.panelFg
                      font.family: root.panelFont
                      font.pixelSize: Style.font.body
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - statusLabel.implicitWidth - Style.spacing.rowGap)
                    }

                    Text {
                      id: statusLabel
                      text: modelData.statusText
                      color: modelData.statusColor
                      font.family: root.panelFont
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      horizontalAlignment: Text.AlignRight
                    }
                  }

                  Text {
                    width: parent.width
                    text: modelData.promptSnippet
                    color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.9)
                    font.family: root.panelFont
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.Wrap
                  }

                  Text {
                    width: parent.width
                    text: "elapsed " + modelData.elapsedText + " | read " + modelData.readAgoText
                    color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.7)
                    font.family: root.panelFont
                    font.pixelSize: Style.font.small
                  }
                }

                PanelActionButton {
                  id: jumpButton
                  visible: !!modelData.agentName && modelData.agentName !== ""
                  iconText: "󰌋"
                  tooltipText: "Jump to agent interaction"
                  foreground: root.panelFg
                  fontFamily: root.panelFont
                  anchors.verticalCenter: parent.verticalCenter
                  onClicked: root.jumpToAgent(modelData.agentName)
                }
              }
            }
          }

          Text {
            visible: root.sessionRows.length === 0
            width: parent.width
            text: connected ? "No active agent sessions." : "No session data available while disconnected."
            color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.72)
            font.family: root.panelFont
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
