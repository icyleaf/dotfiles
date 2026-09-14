import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "CalcModel.js" as CalcModel

Item {
  id: root

  // Injected by omarchy-shell when this plugin is summoned.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string expression: ""
  property string result: ""
  property bool resultVisible: false
  property bool qalcAvailable: true
  property bool copied: false
  property var history: []
  property int historyIndex: -1
  property bool helpVisible: false

  // Shares the [menu] surface tokens — themes that style the menu also style
  // the calculator, matching the emojis and clipboard overlays.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(600), panel.width - Style.gapsOut * 2)
  property int inputHeight: Math.max(Style.space(52), Style.font.displayLarge + Style.spacing.controlPaddingY * 2)
  property int rowHeight: Math.max(Style.space(40), Style.font.body + Style.spacing.rowPaddingX * 2)
  property int historyLimit: CalcModel.HISTORY_LIMIT
  property int debounceMs: 150

  readonly property string historyPath: Quickshell.env("HOME") + "/.local/state/omarchy/calculator-history.json"
  readonly property bool inputEmpty: expression.trim() === ""
  readonly property bool showHistory: inputEmpty && history.length > 0 && !helpVisible
  readonly property bool showHelp: inputEmpty && helpVisible
  readonly property bool showHint: inputEmpty && history.length === 0 && !helpVisible
  readonly property int historyVisibleRows: Math.min(history.length, 7)
  readonly property int hintHeight: Math.round(Style.font.body * 1.6)
  readonly property int noticeHeight: Math.round(Style.font.body * 1.6)
  readonly property int historyHeight: historyVisibleRows * rowHeight + Math.max(0, historyVisibleRows - 1) * Style.spacing.xs
  readonly property int helpLineHeight: Math.round(Style.font.body * 1.7)
  readonly property int helpRows: CalcModel.helpRowCount()
  readonly property int helpHeight: helpRows * helpLineHeight
  readonly property var helpSections: CalcModel.helpSections()
  // Tallest a lower section may grow before it starts scrolling.
  readonly property int maxSectionHeight: Math.max(
    Style.space(60),
    panel.height - Style.gapsOut * 2 - contentMargin * 2 - inputHeight - contentSpacing - (qalcAvailable ? 0 : noticeHeight + contentSpacing))
  readonly property int panelHeight: Math.max(
    Style.space(80),
    Math.min(
      contentMargin * 2 + inputHeight + contentSpacing
        + (showHistory ? historyHeight : 0)
        + (showHelp ? Math.min(helpHeight, maxSectionHeight) : 0)
        + (showHint ? hintHeight : 0)
        + (qalcAvailable ? 0 : noticeHeight + contentSpacing),
      panel.height - Style.gapsOut * 2))
  readonly property int cardHeight: Math.min(panelHeight, panel.height - Style.gapsOut * 2)

  function open(payloadJson) {
    root.opened = true
    root.expression = ""
    root.result = ""
    root.resultVisible = false
    root.copied = false
    root.historyIndex = -1
    root.helpVisible = false
    // TextField.text is set imperatively: a QML binding would be broken the
    // moment the user types, and then stop resetting on the next open.
    Qt.callLater(function() {
      input.text = ""
      input.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "icyleaf.calculator")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  // ── History persistence ───────────────────────────────────────────────────

  function loadHistory(raw) {
    root.history = CalcModel.parseHistory(raw)
  }

  function saveHistory() {
    historyFile.setText(CalcModel.serializeHistory(root.history))
  }

  function recordHistory(expr, value) {
    root.history = CalcModel.addHistoryEntry(root.history, { expression: expr, result: value }, root.historyLimit)
    root.saveHistory()
  }

  // ── Evaluation ────────────────────────────────────────────────────────────

  function scheduleEvaluation() {
    root.copied = false
    if (root.expression.trim() === "") {
      root.result = ""
      root.resultVisible = false
      evalTimer.stop()
      return
    }
    evalTimer.restart()
  }

  function applyOutput(output) {
    if (!CalcModel.isEvaluable(root.expression, output)) {
      root.resultVisible = false
      return
    }
    var value = CalcModel.cleanResult(output)
    root.result = value
    root.resultVisible = true
  }

  function copyResult(value) {
    if (!value) return
    // argv form, not stdin: wl-copy exits once it has forked the owner, while
    // piping keeps this Process alive for as long as the selection lives.
    clipProc.command = ["wl-copy", "--type", "text/plain", "--", String(value)]
    clipProc.running = true
    root.copied = true
    copiedReset.restart()
  }

  // Enter: copy and close. Alt+Enter: copy and stay open. When the input is
  // empty, Enter accepts the highlighted history entry. History is written on
  // this commit rather than on every debounce tick, so partial keystrokes
  // (`2`, then `2+`) never make it to disk.
  function accept(keepOpen) {
    var value = ""
    if (root.expression.trim() !== "" && root.resultVisible) {
      value = root.result
      root.recordHistory(root.expression.trim(), value)
    } else if (root.showHistory && root.historyIndex >= 0 && root.historyIndex < root.history.length) {
      value = root.history[root.historyIndex].result
    }
    if (!value) return
    root.copyResult(value)
    if (!keepOpen) root.dismiss()
    else Qt.callLater(function() { input.forceActiveFocus() })
  }

  function moveHistory(delta) {
    if (!root.showHistory) return
    var next = root.historyIndex + delta
    if (next < -1) next = -1
    if (next >= root.history.length) next = root.history.length - 1
    if (next === root.historyIndex) return
    root.historyIndex = next
  }

  // Ctrl+/ swaps the history area between the history list and the help
  // reference. Both only ever show with an empty input, so the toggle is a
  // mode on the same surface.
  function toggleHelp() {
    if (!root.inputEmpty) return
    root.helpVisible = !root.helpVisible
    root.historyIndex = -1
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Component.onCompleted: qalcCheckProc.running = true

  FileView {
    id: historyFile
    path: root.historyPath
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: root.loadHistory("[]")
  }

  Process {
    id: qalcCheckProc
    command: ["which", "qalc"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(code) { root.qalcAvailable = (code === 0) }
  }

  Process {
    id: evalProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyOutput(text)
    }
    onExited: function(code) {
      if (code !== 0) root.resultVisible = false
    }
  }

  Process {
    id: clipProc
    command: []
  }

  Timer {
    id: evalTimer
    interval: root.debounceMs
    repeat: false
    onTriggered: {
      if (!root.qalcAvailable) return
      if (root.expression.trim() === "") return
      evalProc.command = ["qalc", "-t", "--", root.expression]
      evalProc.running = true
    }
  }

  Timer {
    id: copiedReset
    interval: 1200
    repeat: false
    onTriggered: root.copied = false
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "icyleaf-calculator"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Item {
          width: parent.width
          height: root.inputHeight

          TextField {
            id: input
            anchors.fill: parent
            foreground: root.foreground
            accent: Color.accent
            font.pixelSize: Style.font.display
            placeholderText: "Type an expression…"
            onTextChanged: {
              if (root.expression !== text) {
                root.expression = text
                root.historyIndex = -1
                root.scheduleEvaluation()
              }
            }

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.dismiss()
                event.accepted = true
              } else if (event.key === Qt.Key_Slash && (event.modifiers & Qt.ControlModifier)) {
                root.toggleHelp()
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveHistory(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                root.moveHistory(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accept(Boolean(event.modifiers & Qt.AltModifier))
                event.accepted = true
              }
            }
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.spacing.controlPaddingX
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width * 0.5, implicitWidth)
            visible: root.resultVisible
            text: root.copied ? "Copied" : root.result
            color: root.copied ? Color.accent : root.selectedText
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
          }
        }

        Text {
          width: parent.width
          height: root.noticeHeight
          visible: !root.qalcAvailable
          text: "qalc not found — install libqalculate"
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Flickable {
          width: parent.width
          height: Math.min(root.helpHeight, root.maxSectionHeight)
          visible: root.showHelp
          contentWidth: width
          contentHeight: root.helpHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            width: parent.width
            spacing: 0

            Repeater {
              model: root.helpSections

              Column {
                required property var modelData
                width: parent.width
                spacing: 0

                Text {
                  width: parent.width
                  height: root.helpLineHeight
                  text: modelData.title
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.weight: Font.DemiBold
                  verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                  model: modelData.rows

                  Item {
                    required property var modelData
                    width: parent.width
                    height: root.helpLineHeight

                    Text {
                      id: syntaxText
                      anchors.left: parent.left
                      anchors.leftMargin: Style.spacing.rowPaddingX
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.syntax
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      anchors.left: syntaxText.right
                      anchors.leftMargin: Style.spacing.lg
                      anchors.right: parent.right
                      anchors.rightMargin: Style.spacing.rowPaddingX
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.note
                      color: root.foreground
                      opacity: 0.55
                      horizontalAlignment: Text.AlignRight
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }
          }
        }

        ListView {
          width: parent.width
          height: root.historyHeight
          visible: root.showHistory
          clip: true
          model: root.history
          spacing: Style.spacing.xs
          currentIndex: root.historyIndex
          boundsBehavior: Flickable.StopAtBounds

          delegate: Rectangle {
            required property int index
            required property var modelData
            width: ListView.view.width
            height: root.rowHeight
            radius: root.cornerRadius
            color: index === root.historyIndex ? root.selectedBackground : "transparent"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.rowPaddingX
              anchors.right: resultLabel.left
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.expression
              color: index === root.historyIndex ? root.selectedText : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              id: resultLabel
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(parent.width * 0.5, implicitWidth)
              text: modelData.result
              color: root.foreground
              opacity: 0.85
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideRight
            }

            MouseArea {
              anchors.fill: parent
              onClicked: root.copyResult(modelData.result)
            }
          }
        }

        Text {
          width: parent.width
          height: root.hintHeight
          visible: root.showHint
          text: root.qalcAvailable ? "Ctrl+/ for help  ·  try  2+2  ·  10 usd to gbp" : ""
          color: root.foreground
          opacity: 0.58
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
      }
    }
  }
}
