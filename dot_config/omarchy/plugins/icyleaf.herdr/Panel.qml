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
  property var sessionTimestamps: ({})
  property var previewTexts: ({})
  property var pendingPreviewPanes: ([])
  property string currentPreviewPane: ""
  property int disconnectCount: 0

  readonly property int retentionWindowMs: Number(setting("retentionWindowMs", 6000))
  readonly property string promptDensity: String(setting("promptDensity", "compact"))
  readonly property string herdrLaunchCmd: "omarchy-launch-terminal bash -c 'herdr'"
  readonly property int limitCompact: 72
  readonly property int limitExpanded: 144

  readonly property int refreshIntervalMs: 2000
  readonly property color panelFg: bar ? bar.foreground : Color.foreground
  readonly property string panelFont: bar ? bar.fontFamily : Style.font.family
  
  readonly property color widgetColor: {
    if (!connected) return Qt.rgba(panelFg.r, panelFg.g, panelFg.b, 0.62)
    if (aggregateStatus === "needs-input") return Color.urgent
    if (aggregateStatus === "running") return "#e5c07b"
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
    if (status === "running") return "#e5c07b"
    if (status === "idle") return Color.accent
    return Qt.rgba(panelFg.r, panelFg.g, panelFg.b, 0.75)
  }

  function normalizeStatus(value) {
    var raw = String(value || "").toLowerCase().replace(/[_\s]+/g, "-")
    if (raw === "needs-input" || raw === "blocked" || raw === "waiting-input") return "needs-input"
    if (raw === "running" || raw === "busy" || raw === "working") return "running"
    if (raw === "idle" || raw === "done") return "idle"
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
    var limit = promptDensity === "expanded" ? limitExpanded : limitCompact
    return truncateText(compact, limit)
  }

  function parseTimestampMs(value) {
    if (value === undefined || value === null) return -1

    var strVal = String(value).trim()
    var num = Number(strVal)
    if (!isNaN(num) && strVal.length > 0 && /^\d+$/.test(strVal)) {
      if (!isFinite(num) || num <= 0) return -1
      if (num >= 1000000000000) return Math.round(num)
      if (num >= 1000000000) return Math.round(num * 1000)
      return Math.round(num)
    }

    var parsed = Date.parse(strVal)
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
    var needsInputPanes = []
    for (var i = 0; i < agents.length; i++) {
      var agent = agents[i] || {}
      var tokens = agent.tokens || {}
      var labels = agent.state_labels || {}
      var meta = agent.metadata || {}
      var status = normalizeStatus(agent.agent_status)

      var promptRaw = firstString([
        agent.prompt,
        agent.last_prompt,
        agent.current_prompt,
        tokens.prompt,
        tokens.last_prompt,
        tokens.current_prompt,
        labels.prompt,
        labels.last_prompt,
        labels.current_prompt,
        meta.prompt,
        meta.last_prompt,
        meta.current_prompt,
        agent.terminal_title_stripped,
        agent.terminal_title
      ])

      var paneId = firstString([agent.pane_id, agent.agent, agent.terminal_id])
      if (status === "needs-input" && paneId.length > 0) {
        needsInputPanes.push(paneId)
      }

      var now = Date.now()
      var ts = sessionTimestamps[paneId]
      if (!ts) {
        ts = {
          discoveredAt: now,
          status: status,
          statusChangedAt: now
        }
        sessionTimestamps[paneId] = ts
      } else {
        if (ts.status !== status) {
          ts.status = status
          ts.statusChangedAt = now
        }
      }

      var startMs = parseTimestampMs(firstString([
        agent.started_at,
        agent.created_at,
        agent.started_unix_ms,
        tokens.started_at,
        tokens.created_at,
        tokens.started_unix_ms,
        labels.started_at,
        labels.created_at,
        labels.started_unix_ms,
        meta.started_at,
        meta.created_at,
        meta.started_unix_ms
      ]))
      if (startMs < 0) startMs = ts.discoveredAt

      var readMs = parseTimestampMs(firstString([
        agent.last_read_at,
        agent.read_at,
        tokens.last_read_at,
        tokens.read_at,
        labels.last_read_at,
        labels.read_at,
        meta.last_read_at,
        meta.read_at,
        agent.updated_at,
        agent.updated_unix_ms,
        tokens.updated_at,
        tokens.updated_unix_ms,
        labels.updated_at,
        labels.updated_unix_ms,
        meta.updated_at,
        meta.updated_unix_ms
      ]))
      if (readMs < 0) readMs = ts.statusChangedAt

      var recency = Number(agent.state_change_seq)
      if (!isFinite(recency)) recency = Number(agent.revision)
      if (!isFinite(recency)) recency = 0

      var title = firstString([agent.agent, agent.terminal_title_stripped, agent.pane_id, "session"])

      rows.push({
        id: firstString([agent.agent, agent.pane_id, agent.terminal_id, "session-" + i]),
        paneId: paneId,
        title: title,
        agentName: firstString([agent.agent]),
        status: status,
        statusText: statusText(status),
        statusColor: statusColor(status),
        promptSnippet: normalizePrompt(promptRaw),
        previewText: previewTexts[paneId] || "",
        elapsedText: formatElapsed(startMs),
        readAgoText: formatReadAgo(readMs),
        recency: recency
      })
    }

    queuePreviewReads(needsInputPanes)

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
        sessionTimestamps = ({})
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

  function cleanPreviewText(rawText) {
    if (!rawText) return ""
    var lines = String(rawText).split("\n")
    var filtered = []
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      var stripped = line.trim()
      if (/esc to cancel|Gemini|DeepSeek|OpenCode \d|Claude|gpt-|ctrl\+p commands/i.test(stripped)) continue
      if (/^[─━▀═_|-]+$/.test(stripped)) continue
      if (stripped === ">" || stripped === "") continue
      filtered.push(line)
    }
    if (filtered.length > 10) {
      filtered = filtered.slice(filtered.length - 10)
    }
    return filtered.join("\n")
  }

  function fetchNextPreview() {
    if (previewProc.running || !pendingPreviewPanes || pendingPreviewPanes.length === 0) return
    var paneId = pendingPreviewPanes.shift()
    currentPreviewPane = paneId
    previewProc.command = ["herdr", "pane", "read", paneId, "--lines", "20"]
    previewProc.running = true
  }

  function applyPreviewPayload(paneId, text) {
    if (paneId) {
      var nextTexts = Object.assign({}, previewTexts)
      nextTexts[paneId] = cleanPreviewText(text)
      previewTexts = nextTexts

      var updatedRows = sessionRows.slice(0)
      for (var i = 0; i < updatedRows.length; i++) {
        if (updatedRows[i].paneId === paneId) {
          updatedRows[i].previewText = nextTexts[paneId]
        }
      }
      sessionRows = updatedRows
    }
    currentPreviewPane = ""
    fetchNextPreview()
  }

  function queuePreviewReads(needsInputPanes) {
    if (!needsInputPanes || needsInputPanes.length === 0) return
    for (var i = 0; i < needsInputPanes.length; i++) {
      var paneId = needsInputPanes[i]
      if (pendingPreviewPanes.indexOf(paneId) < 0 && currentPreviewPane !== paneId) {
        pendingPreviewPanes.push(paneId)
      }
    }
    fetchNextPreview()
  }

  Process {
    id: previewProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyPreviewPayload(root.currentPreviewPane, text)
    }
  }

  Process {
    id: sendInputProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.refreshSnapshot()
      }
    }
  }

  function sendPaneInput(paneId, text) {
    if (!paneId) return
    var payloadText = text === undefined || text === null ? "" : String(text)
    if (payloadText.length === 0) {
      payloadText = "\n"
    } else if (!payloadText.endsWith("\n")) {
      payloadText += "\n"
    }
    sendInputProc.command = ["herdr", "pane", "send-text", paneId, payloadText]
    sendInputProc.running = true
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

  function jumpToAgent(paneId, agentName) {
    var targetPane = paneId || agentName
    if (!targetPane) {
      jumpProc.command = [
        "omarchy-notification-send",
        "-u", "critical",
        "-g", "⚠️",
        "Jump Failed",
        "No target pane or agent identifier available for this session."
      ]
      jumpProc.running = true
      return
    }
    jumpProc.command = [
      "bash", "-c",
      "pane=\"$1\"\n" +
      "if command -v hyprctl &>/dev/null; then\n" +
      "  address=$(hyprctl clients -j 2>/dev/null | jq -r '[.[] | select(((.title // \"\") | ascii_downcase | contains(\"herdr\")) or ((.class // \"\") | ascii_downcase | contains(\"ghostty\")) or ((.class // \"\") | ascii_downcase | contains(\"kitty\")) or ((.class // \"\") | ascii_downcase | contains(\"alacritty\")) or ((.class // \"\") | ascii_downcase | contains(\"foot\")) or ((.class // \"\") | ascii_downcase | contains(\"wezterm\")))] | first.address // empty')\n" +
      "  if [[ -n \"$address\" ]]; then\n" +
      "    hyprctl dispatch focuswindow \"address:$address\" >/dev/null\n" +
      "  else\n" +
      "    omarchy-launch-terminal bash -c 'herdr' &\n" +
      "  fi\n" +
      "fi\n" +
      "if command -v herdr &>/dev/null && [[ -n \"$pane\" ]]; then\n" +
      "  herdr agent focus \"$pane\" >/dev/null 2>&1\n" +
      "fi",
      "--",
      targetPane
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

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon()
    foreground: root.widgetColor
    fontSize: Style.font.caption
    horizontalMargin: 6
    verticalPadding: 6
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
              id: sessionCard
              required property var modelData
              readonly property string sessionPaneId: modelData.paneId || ""

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

                  Column {
                    id: needsInputCol
                    visible: modelData.status === "needs-input"
                    width: parent.width
                    spacing: Style.spacing.xs

                    Rectangle {
                      visible: !!modelData.previewText
                      width: parent.width
                      radius: Style.cornerRadius
                      color: Qt.rgba(0, 0, 0, 0.28)
                      border.width: 1
                      border.color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.45)
                      implicitHeight: previewCol.implicitHeight + Style.spacing.xs * 2

                      Column {
                        id: previewCol
                        anchors.fill: parent
                        anchors.margins: Style.spacing.xs
                        spacing: 2

                        Text {
                          text: "Terminal Question Preview:"
                          color: Color.urgent
                          font.family: root.panelFont
                          font.pixelSize: Style.font.caption
                          font.bold: true
                        }

                        Text {
                          width: parent.width
                          text: modelData.previewText
                          color: root.panelFg
                          font.family: root.panelFont
                          font.pixelSize: Style.font.caption
                          wrapMode: Text.Wrap
                        }
                      }
                    }

                    Row {
                      spacing: Style.spacing.xs
                      width: parent.width

                      Repeater {
                        model: [
                          { label: "1", val: "1" },
                          { label: "2", val: "2" },
                          { label: "3", val: "3" },
                          { label: "4", val: "4" },
                          { label: "y", val: "y" },
                          { label: "n", val: "n" },
                          { label: "↵", val: "" }
                        ]

                        delegate: Rectangle {
                          required property var modelData
                          width: 28
                          height: 24
                          radius: Style.cornerRadius
                          color: presetMouse.containsMouse ? Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.25) : Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.12)
                          border.width: 1
                          border.color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.3)

                          Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.panelFg
                            font.family: root.panelFont
                            font.pixelSize: Style.font.caption
                            font.bold: true
                          }

                          MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.sendPaneInput(sessionCard.sessionPaneId, modelData.val)
                          }
                        }
                      }
                    }

                    Row {
                      width: parent.width
                      spacing: Style.spacing.xs

                      Rectangle {
                        width: parent.width - sendBtn.width - parent.spacing
                        height: 26
                        radius: Style.cornerRadius
                        color: Qt.rgba(0, 0, 0, 0.35)
                        border.width: 1
                        border.color: customInput.activeFocus ? Color.accent : Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.3)

                        TextInput {
                          id: customInput
                          anchors.fill: parent
                          anchors.margins: 4
                          color: root.panelFg
                          font.family: root.panelFont
                          font.pixelSize: Style.font.caption
                          selectByMouse: true
                          clip: true
                          onAccepted: {
                            if (text.length > 0) {
                              root.sendPaneInput(sessionCard.sessionPaneId, text)
                              text = ""
                            }
                          }
                        }
                      }

                      Button {
                        id: sendBtn
                        text: "Send"
                        bordered: true
                        focusable: true
                        foreground: root.panelFg
                        fontFamily: root.panelFont
                        height: 26
                        onClicked: {
                          if (customInput.text.length > 0) {
                            root.sendPaneInput(sessionCard.sessionPaneId, customInput.text)
                            customInput.text = ""
                          }
                        }
                      }
                    }
                  }

                  Text {
                    width: parent.width
                    text: "elapsed " + modelData.elapsedText + " | read " + modelData.readAgoText
                    color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.7)
                    font.family: root.panelFont
                    font.pixelSize: Style.font.caption
                  }
                }

                PanelActionButton {
                  id: jumpButton
                  visible: (!!modelData.paneId && modelData.paneId !== "") || (!!modelData.agentName && modelData.agentName !== "")
                  iconText: "󰌋"
                  tooltipText: "Jump to agent interaction"
                  foreground: root.panelFg
                  fontFamily: root.panelFont
                  anchors.verticalCenter: parent.verticalCenter
                  onClicked: root.jumpToAgent(modelData.paneId, modelData.agentName)
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
