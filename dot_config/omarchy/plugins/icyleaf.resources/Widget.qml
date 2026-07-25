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

  readonly property string displayText: " " + String(cpuPercent).padStart(2, "0") + "%  󰍛 " + String(memoryPercent).padStart(2, "0") + "%"

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(value)))
  }

  function updateFromProc(text) {
    var lines = String(text || "").split("\n")
    var cpuLine = lines.length > 0 ? lines[0].trim() : ""
    var memLine = lines.length > 1 ? lines[1].trim() : ""

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

    var memMatch = memLine.match(/^Mem:\s+(\d+)\s+(\d+)/)
    if (memMatch) {
      var totalMemory = Number(memMatch[1])
      var availableMemory = Number(memMatch[2])
      if (totalMemory > 0) root.memoryPercent = clampPercent(((totalMemory - availableMemory) / totalMemory) * 100)
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statsProc
    command: ["bash", "-c", "awk '/^cpu / { print; exit }' /proc/stat; awk '/^MemTotal:/ { total=$2 } /^MemAvailable:/ { available=$2 } END { printf \"Mem: %s %s\\n\", total, available }' /proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateFromProc(text)
    }
  }

  Timer {
    interval: 2000
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