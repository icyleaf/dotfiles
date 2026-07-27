import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "icyleaf.resources"
  ipcTarget: "icyleaf.resources"

  IpcHandler {
    target: root.ipcTarget

    function open() { root.openFromHotkey() }
    function close() { root.close() }
    function show() { root.openFromHotkey() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
  }

  // ── Telemetry State ──────────────────────────────────────────────────────
  property string hostName: ""
  property string kernelVer: ""
  property string uptimeText: ""

  property int cpuPercent: 0
  property int memoryPercent: 0
  property int cpuCurrentMHz: 0
  property int cpuMaxMHz: 0
  property int cpuTemperature: 0
  property int memoryTotalKiB: 0
  property int memoryAvailableKiB: 0
  property string cpuModel: ""

  property real swapPercent: 0
  property real diskPercent: 0
  property real gpuPercent: -1
  property real loadPercent: 0

  property real memUsedGb: 0
  property real memTotalGb: 0
  property real swapUsedGb: 0
  property real swapTotalGb: 0
  property real diskUsedGb: 0
  property real diskTotalGb: 0
  property real gpuMemUsedMb: 0
  property real gpuMemTotalMb: 0
  property int gpuTemp: 0
  property int cpuCores: 1
  property string gpuName: "GPU"
  property string diskMount: "/"

  property real load1: 0
  property real load5: 0
  property real load15: 0
  property var prevCpu: ({ idle: 0, total: 0 })

  readonly property int refreshSeconds: Math.max(1, Number(setting("refreshSeconds", 2)) || 2)
  readonly property string diskPath: String(setting("diskPath", "/") || "/")
  readonly property bool showGpu: boolSetting("showGpu", true)
  readonly property string displayMode: String(setting("displayMode", "utilization"))

  readonly property color panelFg: bar ? bar.foreground : Color.foreground
  readonly property string panelFont: bar ? bar.fontFamily : Style.font.family
  readonly property url statusScriptUrl: Qt.resolvedUrl("status.sh")
  readonly property string statusScript: decodeURIComponent(String(statusScriptUrl).replace(/^file:\/\//, ""))

  readonly property real memoryUsedGiB: memoryTotalKiB > 0 ? (memoryTotalKiB - memoryAvailableKiB) / (1024 * 1024) : 0
  readonly property real memoryTotalGiB: memoryTotalKiB > 0 ? memoryTotalKiB / (1024 * 1024) : 0

  // ── Status Bar Text & Visuals ───────────────────────────────────────────
  readonly property string displayText: mainGlyph() + " " + mainValueText() + "  󰍛 " + String(memoryPercent).padStart(2, "0") + "%"
  readonly property string tooltipText: buildTooltip()
  readonly property color displayForeground: usageColor(mainMetricPercent(), mainMetricTemperature())

  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(value)))
  }

  function utilizationGlyph() {
    if (cpuPercent > 90) return ""
    if (cpuPercent > 60) return "󰓅"
    if (cpuPercent > 30) return "󰾅"
    return "󰾆"
  }

  function mainGlyph() {
    return displayMode === "temperature" ? temperatureGlyph() : utilizationGlyph()
  }

  function mainValueText() {
    if (displayMode === "temperature") return String(cpuTemperature).padStart(2, "0") + "°C"
    return String(cpuPercent).padStart(2, "0") + "%"
  }

  function mainMetricPercent() {
    return displayMode === "temperature" ? 0 : cpuPercent
  }

  function mainMetricTemperature() {
    return displayMode === "temperature" ? cpuTemperature : 0
  }

  function usageColor(percent, temperature) {
    if (temperature > 0) {
      if (temperature >= 85) return Color.urgent
      if (temperature >= 65) return "#ff8c00"
      if (temperature >= 45) return "#6fb6ff"
      return Color.foreground
    }

    if (percent >= 90) return Color.urgent
    if (percent >= 70) return "#ff8c00"
    if (percent >= 40) return "#e0b64c"
    return Color.foreground
  }

  function temperatureGlyph() {
    if (cpuTemperature >= 85) return ""
    if (cpuTemperature >= 65) return ""
    if (cpuTemperature >= 45) return ""
    return ""
  }

  function buildTooltip() {
    var lines = []
    if (cpuModel) lines.push(cpuModel)

    var cpuLine = utilizationGlyph() + " Utilization: " + cpuPercent + "%"
    if (cpuTemperature > 0) cpuLine += "   " + temperatureGlyph() + " " + cpuTemperature + "°C"
    lines.push(cpuLine)

    if (cpuCurrentMHz > 0 || cpuMaxMHz > 0) {
      var clockLine = " Clock Speed: " + cpuCurrentMHz
      if (cpuMaxMHz > 0) clockLine += "/" + cpuMaxMHz
      clockLine += " MHz"
      lines.push(clockLine)
    }

    lines.push("󰍛 Memory: " + memoryPercent + "% (" + memoryUsedGiB.toFixed(1) + "/" + memoryTotalGiB.toFixed(1) + " GiB)")
    return lines.join("\n")
  }

  // ── System Health Status ────────────────────────────────────────────────
  readonly property string systemHealthText: {
    if (cpuPercent >= 85 || memoryPercent >= 90 || (gpuPercent >= 0 && gpuTemp >= 82)) return "CRITICAL LOAD"
    if (cpuPercent >= 70 || memoryPercent >= 75 || (gpuPercent >= 0 && gpuTemp >= 74)) return "HEAVY LOAD"
    if (cpuPercent >= 40 || memoryPercent >= 50) return "MODERATE"
    return "HEALTHY"
  }

  readonly property color systemHealthColor: {
    if (cpuPercent >= 85 || memoryPercent >= 90 || (gpuPercent >= 0 && gpuTemp >= 82)) return Color.urgent
    if (cpuPercent >= 70 || memoryPercent >= 75 || (gpuPercent >= 0 && gpuTemp >= 74)) return "#e5c07b"
    return Color.accent
  }

  // ── Animated Phrase Generator ────────────────────────────────────────────
  readonly property var idlePhrases: [
    "Watching electrons", "Counting cycles", "Minding registers",
    "Tending clocks", "Nursing circuits", "Herding threads",
    "Babysitting bits", "Sipping watts", "Chilling cores",
    "Tickling timers", "Humming quietly", "Breathing easy"
  ]

  readonly property var cpuBusyPhrases: [
    "Crunching numbers", "Churning cycles", "Burning silicon",
    "Grinding cores", "Chewing workloads", "Racing pipelines",
    "Juggling threads", "Flexing muscles", "Working overtime"
  ]

  readonly property var cpuHotPhrases: [
    "Melting cores", "Sweating silicon", "Roasting threads",
    "Maxing out", "Sprinting hard", "Overclocking dignity",
    "Blowing fans", "Redlining hard"
  ]

  readonly property var memHeavyPhrases: [
    "Hoarding memory", "Swapping secrets", "Squeezing RAM",
    "Filling buckets", "Juggling pages", "Borrowing headroom",
    "Cramming heaps", "Evicting pages"
  ]

  readonly property var diskFullPhrases: [
    "Running low", "Hoarding inodes", "Packing storage",
    "Filling shelves", "Begging for space", "Evicting files"
  ]

  readonly property var gpuBusyPhrases: [
    "Shading pixels", "Grinding polygons", "Rasterizing madly",
    "Blasting shaders", "Tracing rays", "Painting frames"
  ]

  property int phraseIndex: 0
  readonly property var activePhrases: {
    if (gpuPercent >= 0 && gpuTemp >= 75) return gpuHotPhrases
    if (cpuPercent >= 75)                 return cpuHotPhrases
    if (memoryPercent >= 75)              return memHeavyPhrases
    if (diskPercent >= 75)                return diskFullPhrases
    if (gpuPercent >= 60)                 return gpuBusyPhrases
    if (cpuPercent >= 40)                 return cpuBusyPhrases
    return idlePhrases
  }

  readonly property string heroPhrase: activePhrases[phraseIndex % activePhrases.length]

  Timer {
    id: phraseTimer
    interval: 3200
    running: root.opened
    repeat: true
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation {
      target: heroLabel
      property: "metaOpacity"
      to: 0
      duration: 180
      easing.type: Easing.OutQuad
    }
    ScriptAction {
      script: root.phraseIndex = (root.phraseIndex + 1) % root.activePhrases.length
    }
    PropertyAnimation {
      target: heroLabel
      property: "metaOpacity"
      to: 1
      duration: 260
      easing.type: Easing.InQuad
    }
  }

  // ── Data Processing Helpers ──────────────────────────────────────────────
  function boolSetting(key, fallback) {
    var value = setting(key, fallback)
    if (value === true || value === false) return value
    var text = String(value).toLowerCase()
    return text === "true" || text === "1" || text === "yes"
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function parseNumber(value, fallback) {
    var n = parseFloat(String(value || "").trim())
    return isNaN(n) ? fallback : n
  }

  function percentText(value) {
    return value < 0 ? "N/A" : Math.round(value) + "%"
  }

  function gbText(value) {
    if (!isFinite(value) || value <= 0) return "N/A"
    return value.toFixed(value >= 10 ? 0 : 1) + " GB"
  }

  function mbAsGbText(value) {
    if (!isFinite(value) || value <= 0) return "N/A"
    var gb = value / 1024
    return gb.toFixed(gb >= 10 ? 0 : 1) + " GB"
  }

  function statusColorFor(pct) {
    if (pct === undefined || pct === null || pct <= 0) return Color.accent
    if (pct >= 85) return Color.urgent
    if (pct >= 70) return "#e5c07b"
    return Color.accent
  }

  function updateCpuTotals(idle, total, cores) {
    cpuCores = Math.max(1, cores || 1)
    var idleDiff = idle - prevCpu.idle
    var totalDiff = total - prevCpu.total
    if (prevCpu.total > 0 && totalDiff > 0) {
      cpuPercent = clampPercent((1 - idleDiff / totalDiff) * 100)
    }
    prevCpu = { idle: idle, total: total }
    loadPercent = clampPercent((load1 / cpuCores) * 100)
  }

  function updateLoad(one, five, fifteen) {
    load1 = parseNumber(one, 0)
    load5 = parseNumber(five, 0)
    load15 = parseNumber(fifteen, 0)
    loadPercent = clampPercent((load1 / Math.max(1, cpuCores)) * 100)
  }

  function updateStats(raw) {
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split("\t")
      if (parts.length < 2) continue
      if (parts[0] === "host") {
        hostName = parts[1] || ""
        kernelVer = parts[2] || ""
        uptimeText = parts[3] || ""
      } else if (parts[0] === "cpu") {
        updateCpuTotals(parseInt(parts[1], 10) || 0, parseInt(parts[2], 10) || 0, parseInt(parts[3], 10) || 1)
      } else if (parts[0] === "memory") {
        memoryPercent = clampPercent(parseNumber(parts[1], 0))
        memUsedGb = parseNumber(parts[2], 0)
        memTotalGb = parseNumber(parts[3], 0)
        swapPercent = clampPercent(parseNumber(parts[4], 0))
        swapUsedGb = parseNumber(parts[5], 0)
        swapTotalGb = parseNumber(parts[6], 0)
        memoryTotalKiB = parseInt(parts[7], 10) || 0
        memoryAvailableKiB = parseInt(parts[8], 10) || 0
      } else if (parts[0] === "load") {
        updateLoad(parts[1], parts[2], parts[3])
      } else if (parts[0] === "disk") {
        diskPercent = clampPercent(parseNumber(parts[1], 0))
        diskUsedGb = parseNumber(parts[2], 0)
        diskTotalGb = parseNumber(parts[3], 0)
        diskMount = parts[4] || diskPath
      } else if (parts[0] === "gpu") {
        gpuPercent = parts[1] === "" ? -1 : clampPercent(parseNumber(parts[1], -1))
        gpuMemUsedMb = parseNumber(parts[2], 0)
        gpuMemTotalMb = parseNumber(parts[3], 0)
        gpuTemp = Math.round(parseNumber(parts[4], 0))
        gpuName = parts[5] || "GPU"
      } else if (parts[0] === "cpu_detail") {
        cpuTemperature = parseInt(parts[1], 10) || 0
        cpuMaxMHz = parseInt(parts[2], 10) || 0
        cpuCurrentMHz = parseInt(parts[3], 10) || 0
        cpuModel = parts[4] || ""
      }
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statsProc
    command: ["bash", root.statusScript, root.diskPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStats(text)
    }
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool launchBusy: false

  function launchBtop() {
    if (launchBusy) return
    launchBusy = true
    launchDebounceTimer.restart()
    root.close()
    if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }

  Timer {
    id: launchDebounceTimer
    interval: 800
    onTriggered: root.launchBusy = false
  }

  // ── Bar Widget Button (Left-click toggles panel, Right-click opens btop) ──
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    foreground: root.displayForeground
    fontSize: Style.font.caption
    horizontalMargin: 6
    verticalPadding: 6
    tooltipText: root.tooltipText
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) {
        root.refresh()
        root.toggle()
      } else {
        root.launchBtop()
      }
    }
  }

  // ── Clean System Telemetry Panel ──────────────────────────────────────────
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    onOpenChanged: {
      if (open) root.refresh()
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.launchBtop()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      // Custom key triggers
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_R) {
          root.refresh()
          event.accepted = true
        }
      }

      Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // ── 1. Hero Section Header ─────────────────────────────────────────
        PanelHero {
          id: heroLabel
          width: parent.width
          title: root.hostName !== "" ? root.hostName : "System Monitor"
          meta: root.heroPhrase
          detail: root.systemHealthText
          foreground: root.panelFg
          fontFamily: root.panelFont
          iconComponent: Text {
            text: "󰍛"
            color: root.systemHealthColor
            font.family: root.panelFont
            font.pixelSize: Style.space(32)
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        PanelSeparator { foreground: root.panelFg }

        // ── 2. Processing & CPU Section ────────────────────────────────────
        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "PROCESSING & CPU"
            foreground: root.panelFg
            fontFamily: root.panelFont
          }

          StatRowItem {
            width: parent.width
            label: "Processor (" + root.cpuCores + " Cores)"
            detail: "Load " + root.load1.toFixed(2) + " · " + root.load5.toFixed(2) + " · " + root.load15.toFixed(2)
            valueText: root.percentText(root.cpuPercent)
            percent: root.cpuPercent
            badgeIcon: "󰍛"
            accentColor: root.statusColorFor(root.cpuPercent)
          }

          StatRowItem {
            width: parent.width
            visible: root.cpuTemperature > 0 || root.cpuCurrentMHz > 0
            label: root.cpuModel !== "" ? root.cpuModel : "Processor Hardware"
            detail: "Clock speed: " + root.cpuCurrentMHz + (root.cpuMaxMHz > 0 ? " / " + root.cpuMaxMHz : "") + " MHz"
            valueText: root.cpuTemperature > 0 ? root.cpuTemperature + "°C" : "N/A"
            percent: root.cpuMaxMHz > 0 ? (root.cpuCurrentMHz / root.cpuMaxMHz) * 100 : 0
            badgeIcon: ""
            accentColor: root.cpuTemperature >= 75 ? Color.urgent : (root.cpuTemperature >= 55 ? "#e5c07b" : Color.accent)
          }
        }

        PanelSeparator { foreground: root.panelFg }

        // ── 3. Memory & Storage Section ───────────────────────────────────
        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "MEMORY & STORAGE"
            foreground: root.panelFg
            fontFamily: root.panelFont
          }

          StatRowItem {
            width: parent.width
            label: "Memory (RAM)"
            detail: root.gbText(root.memUsedGb) + " / " + root.gbText(root.memTotalGb) + " used"
            valueText: root.percentText(root.memoryPercent)
            percent: root.memoryPercent
            badgeIcon: "󰘚"
            accentColor: root.statusColorFor(root.memoryPercent)
          }

          StatRowItem {
            width: parent.width
            visible: root.swapTotalGb > 0
            label: "Swap Memory"
            detail: root.gbText(root.swapUsedGb) + " / " + root.gbText(root.swapTotalGb) + " used"
            valueText: root.percentText(root.swapPercent)
            percent: root.swapPercent
            badgeIcon: "󰓡"
            accentColor: root.statusColorFor(root.swapPercent)
          }

          StatRowItem {
            width: parent.width
            label: "Storage (" + root.diskMount + ")"
            detail: root.gbText(root.diskUsedGb) + " / " + root.gbText(root.diskTotalGb) + " used (" + root.gbText(root.diskTotalGb - root.diskUsedGb) + " free)"
            valueText: root.percentText(root.diskPercent)
            percent: root.diskPercent
            badgeIcon: "󰋊"
            accentColor: root.statusColorFor(root.diskPercent)
          }
        }

        // ── 4. Graphics & Acceleration Section (Optional) ──────────────────
        Column {
          width: parent.width
          visible: root.showGpu
          spacing: Style.space(8)

          PanelSeparator { foreground: root.panelFg }

          PanelSectionHeader {
            text: "GRAPHICS & ACCELERATION"
            foreground: root.panelFg
            fontFamily: root.panelFont
          }

          StatRowItem {
            width: parent.width
            label: "Graphics Card"
            detail: root.gpuName === "Unavailable"
              ? "Unavailable"
              : root.gpuName + (root.gpuMemTotalMb > 0 ? " · VRAM " + root.mbAsGbText(root.gpuMemUsedMb) + " / " + root.mbAsGbText(root.gpuMemTotalMb) : "") + (root.gpuTemp > 0 ? " · " + root.gpuTemp + "°C" : "")
            valueText: root.percentText(root.gpuPercent)
            percent: root.gpuPercent
            badgeIcon: "󰢮"
            accentColor: root.statusColorFor(root.gpuPercent)
          }
        }
      }
    }
  }

  // ── StatRowItem Component ────────────────────────────────────────────────
  component StatRowItem: Item {
    id: rowItem
    property string label: ""
    property string detail: ""
    property string valueText: ""
    property string badgeIcon: ""
    property real percent: 0
    property color accentColor: Color.accent

    implicitHeight: Style.space(40)

    Item {
      anchors.fill: parent

      // Clean Icon
      Text {
        id: badge
        text: rowItem.badgeIcon
        color: root.panelFg
        font.family: root.panelFont
        font.pixelSize: Style.space(24)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      // Title & Sub-detail Column
      Column {
        id: infoCol
        anchors.left: badge.right
        anchors.leftMargin: Style.space(12)
        anchors.right: meterCol.left
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          text: rowItem.label
          color: root.panelFg
          font.family: root.panelFont
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: rowItem.detail
          color: Color.muted
          font.family: root.panelFont
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      // Percentage & Meter Bar Column
      Column {
        id: meterCol
        width: Style.space(80)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(3)

        Text {
          width: parent.width
          text: rowItem.valueText
          color: rowItem.accentColor
          font.family: root.panelFont
          font.pixelSize: Style.font.body
          font.bold: true
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
        }

        Rectangle {
          width: parent.width
          height: Style.space(4)
          radius: height / 2
          color: Qt.rgba(root.panelFg.r, root.panelFg.g, root.panelFg.b, 0.14)

          Rectangle {
            width: parent.width * Math.max(0, Math.min(100, rowItem.percent)) / 100
            height: parent.height
            radius: parent.radius
            color: rowItem.accentColor
            visible: rowItem.percent >= 0

            Behavior on width {
              NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
          }
        }
      }
    }
  }
}
