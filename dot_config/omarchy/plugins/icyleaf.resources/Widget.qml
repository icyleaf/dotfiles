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
  property real previousIdle: -1
  property real previousTotal: -1
  readonly property int updateInterval: 2000

  readonly property string displayText: "\uf4bc " + String(cpuPercent).padStart(2, "0") + "%  󰍛 " + String(memoryPercent).padStart(2, "0") + "%"

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(value)))
  }

  function updateFromProc(text) {
    var lines = String(text || "").split("\n")
    var cpuLine = lines.length > 0 ? lines[0].trim() : ""
    var totalMemory = 0
    var availableMemory = 0

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
    }

    if (totalMemory > 0 && availableMemory >= 0) {
      root.memoryPercent = clampPercent(((totalMemory - availableMemory) / totalMemory) * 100)
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statsProc
    command: ["bash", "-c", "cat /proc/stat /proc/meminfo"]
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
    verticalPadding: 6
  }
}