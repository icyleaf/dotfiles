import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "icyleaf.resources"

  property int cpuPercent: 0
  property int memoryPercent: 0
  property int cpuCurrentMHz: 0
  property int cpuMaxMHz: 0
  property int cpuTemperature: 0
  property int memoryTotalKiB: 0
  property int memoryAvailableKiB: 0
  property string cpuModel: ""
  property real previousIdle: -1
  property real previousTotal: -1
  readonly property int updateInterval: 2000
  readonly property real memoryUsedGiB: memoryTotalKiB > 0 ? (memoryTotalKiB - memoryAvailableKiB) / (1024 * 1024) : 0
  readonly property real memoryTotalGiB: memoryTotalKiB > 0 ? memoryTotalKiB / (1024 * 1024) : 0

  readonly property string displayText: " " + String(cpuPercent).padStart(2, "0") + "%  󰍛 " + String(memoryPercent).padStart(2, "0") + "%"
  readonly property string tooltipText: buildTooltip()

  function refreshStatic() {
    if (!staticProc.running) staticProc.running = true
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(value)))
  }

  function buildTooltip() {
    var lines = []
    if (cpuModel) lines.push(cpuModel)

    var cpuLine = " Utilization: " + cpuPercent + "%"
    if (cpuTemperature > 0) cpuLine += "    " + cpuTemperature + "°C"
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

  function updateStaticInfo(text) {
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (line.indexOf("CPU_MODEL ") === 0) root.cpuModel = line.slice(10).trim()
      if (line.indexOf("CPU_MAX_MHZ ") === 0) root.cpuMaxMHz = Number(line.slice(12).trim())
    }
  }

  function updateFromProc(text) {
    var lines = String(text || "").split("\n")
    var cpuLine = lines.length > 0 ? lines[0].trim() : ""
    var totalMemory = root.memoryTotalKiB
    var availableMemory = root.memoryAvailableKiB

    var cpuMatch = cpuLine.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
    if (cpuMatch) {
      var user = Number(cpuMatch[1])
      var nice = Number(cpuMatch[2])
      var system = Number(cpuMatch[3])
      var idle = Number(cpuMatch[4])
      var iowait = Number(cpuMatch[5])
      var irq = Number(cpuMatch[6])
      var softirq = Number(cpuMatch[7])
      var steal = Number(cpuMatch[8])

      var currentIdle = idle + iowait
      var currentTotal = user + nice + system + idle + iowait + irq + softirq + steal

      if (previousTotal >= 0 && currentTotal > previousTotal) {
        var idleDelta = currentIdle - previousIdle
        var totalDelta = currentTotal - previousTotal
        if (totalDelta > 0) root.cpuPercent = clampPercent((1 - idleDelta / totalDelta) * 100)
      }

      root.previousIdle = currentIdle
      root.previousTotal = currentTotal
    }

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      var totalMatch = line.match(/^MemTotal:\s+(\d+)/)
      if (totalMatch) totalMemory = Number(totalMatch[1])

      var availableMatch = line.match(/^MemAvailable:\s+(\d+)/)
      if (availableMatch) availableMemory = Number(availableMatch[1])

      var clockMatch = line.match(/^CPU_CUR_MHZ\s+(\d+)/)
      if (clockMatch) root.cpuCurrentMHz = Number(clockMatch[1])

      var tempMatch = line.match(/^CPU_TEMP\s+(-?\d+)/)
      if (tempMatch) root.cpuTemperature = Number(tempMatch[1])
    }

    if (totalMemory > 0 && availableMemory >= 0) {
      root.memoryTotalKiB = totalMemory
      root.memoryAvailableKiB = availableMemory
      root.memoryPercent = clampPercent(((totalMemory - availableMemory) / totalMemory) * 100)
    }
  }

  Component.onCompleted: {
    refreshStatic()
    refresh()
  }

  Process {
    id: staticProc
    command: ["bash", "-c", "lscpu | awk -F ':' '/Model name/ { gsub(/^[ \\t]+|[ \\t]+$/, \"\", $2); sub(/ CPU.*/, \"\", $2); print \"CPU_MODEL \" $2 } /CPU max MHz/ { gsub(/^[ \\t]+|[ \\t]+$/, \"\", $2); sub(/\\..*/, \"\", $2); print \"CPU_MAX_MHZ \" $2 }'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStaticInfo(text)
    }
  }

  Process {
    id: statsProc
    command: ["bash", "-c", "cat /proc/stat /proc/meminfo; perl -ne 'BEGIN { $sum = 0; $count = 0 } if (/cpu MHz\\s+:\\s+([\\d.]+)/) { $sum += $1; $count++ } END { if ($count > 0) { printf \"CPU_CUR_MHZ %.0f\\n\", $sum / $count } }' /proc/cpuinfo; sensors 2>/dev/null | awk '/^Package id 0:|^Tctl:|^temp1:/ { match($0, /[+]?[0-9]+(\\.[0-9]+)?/, parts); if (parts[0] != \"\") { sub(/\\..*/, \"\", parts[0]); print \"CPU_TEMP \" parts[0]; exit } }'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateFromProc(text)
    }
  }

  Timer {
    interval: root.updateInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.tooltipText
    verticalPadding: 6
  }
}