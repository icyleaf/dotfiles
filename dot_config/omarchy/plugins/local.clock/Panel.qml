import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "local.clock"
  ipcTarget: "local.clock"
  manageIpc: false

  property bool alt: false
  property date displayDate: clock.date
  property date panelMonth: new Date(displayDate.getFullYear(), displayDate.getMonth(), 1)

  readonly property bool weekStartsSunday: String(setting("firstDayOfWeek", "sunday")).toLowerCase() !== "monday"
  readonly property var weekdayLabels: weekStartsSunday
    ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  readonly property bool showSettingsGear: setting("showSettingsGear", true) === true
    || String(setting("showSettingsGear", "true")).toLowerCase() === "true"
  readonly property string settingsCommand: String(setting("settingsCommand", "omarchy-shell shell summon local.settings"))
  readonly property bool gearRevealed: showSettingsGear && (clockHover.hovered || gearHover.hovered || vertClockHover.hovered)
  readonly property string activeFormat: alt
    ? setting("formatAlt", "dd MMMM 'W'ww yyyy")
    : (bar && bar.vertical ? setting("verticalFormat", "HH\n—\nmm") : setting("format", "dddd HH:mm"))

  function refresh() {
    displayDate = new Date()
  }

  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  function isoWeekLiteral(date) {
    var week = isoWeek(date)
    return (week < 10 ? "0" : "") + week
  }

  function formatted(date) {
    return Qt.formatDateTime(date, activeFormat.replace(/ww/g, isoWeekLiteral(date)))
  }

  function sameDay(a, b) {
    return a && b
      && a.getFullYear() === b.getFullYear()
      && a.getMonth() === b.getMonth()
      && a.getDate() === b.getDate()
  }

  function startOfMonth(date) {
    return new Date(date.getFullYear(), date.getMonth(), 1)
  }

  function showToday() {
    displayDate = new Date()
    panelMonth = startOfMonth(displayDate)
  }

  function moveMonth(delta) {
    panelMonth = new Date(panelMonth.getFullYear(), panelMonth.getMonth() + delta, 1)
  }

  function monthCells() {
    var first = startOfMonth(panelMonth)
    var firstWeekday = weekStartsSunday ? 0 : 1
    var offset = (first.getDay() - firstWeekday + 7) % 7
    var last = new Date(panelMonth.getFullYear(), panelMonth.getMonth() + 1, 0)
    var rows = Math.ceil((offset + last.getDate()) / 7)
    var count = rows * 7
    var start = new Date(first.getFullYear(), first.getMonth(), 1 - offset)
    var out = []
    for (var i = 0; i < count; i++) {
      var date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
      out.push({
        day: date.getDate(),
        date: date,
        currentMonth: date.getMonth() === panelMonth.getMonth(),
        today: sameDay(date, new Date())
      })
    }
    return out
  }

  implicitWidth: root.bar && root.bar.vertical ? vertLayout.implicitWidth : button.implicitWidth
  implicitHeight: root.bar && root.bar.vertical ? vertLayout.implicitHeight : button.implicitHeight

  onOpenedChanged: if (opened) panelMonth = startOfMonth(displayDate)

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }

  IpcHandler {
    target: "local.clock"
    function refresh(): void { root.refresh() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Row {
    id: button
    anchors.fill: parent
    spacing: 0
    visible: !root.bar || !root.bar.vertical

    HoverHandler { id: clockHover }

    WidgetButton {
      id: gearButton
      bar: root.bar
      visible: root.showSettingsGear
      text: ""
      keepSpace: root.showSettingsGear
      concealed: !root.gearRevealed
      interactive: root.gearRevealed
      horizontalMargin: 6.5
      verticalPadding: 6
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.LeftButton && root.bar && root.settingsCommand)
          root.bar.run(root.settingsCommand)
      }
      HoverHandler { id: gearHover }
    }

    WidgetButton {
      id: clockButton
      bar: root.bar
      text: root.formatted(root.displayDate)
      horizontalMargin: 8.75
      verticalPadding: 8.75
      onPressed: function(mouseButton) {
        if (!root.bar) return
        if (mouseButton === Qt.RightButton) root.bar.run("omarchy-menu-timezone")
        else if (mouseButton === Qt.MiddleButton) root.alt = !root.alt
        else root.toggle()
      }
    }
  }

  Column {
    id: vertLayout
    visible: root.bar && root.bar.vertical
    spacing: 2
    HoverHandler { id: vertClockHover }

    WidgetButton {
      bar: root.bar
      visible: root.showSettingsGear
      text: ""
      horizontalMargin: 2
      verticalPadding: 2
      concealed: !root.gearRevealed
      interactive: root.gearRevealed
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.LeftButton && root.bar && root.settingsCommand)
          root.bar.run(root.settingsCommand)
      }
    }

    WidgetButton {
      id: vertClockButton
      bar: root.bar
      text: root.formatted(root.displayDate)
      horizontalMargin: 4
      verticalPadding: 4
      onPressed: function(mouseButton) {
        if (!root.bar) return
        if (mouseButton === Qt.RightButton) root.bar.run("omarchy-menu-timezone")
        else if (mouseButton === Qt.MiddleButton) root.alt = !root.alt
        else root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.bar && root.bar.vertical ? vertLayout : button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(calendarColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.moveMonth(dx)
      }
      onActivateRequested: root.showToday()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: calendarColumn
        anchors.fill: parent
        spacing: Style.spacing.md

        Row {
          width: parent.width
          spacing: Style.spacing.rowGap

          Text {
            width: parent.width - prevButton.width - nextButton.width - todayButton.width - Style.spacing.rowGap * 3
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(root.panelMonth, "MMMM yyyy")
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }

          Button {
            id: prevButton
            text: "<"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true
            onClicked: root.moveMonth(-1)
          }

          Button {
            id: todayButton
            text: "Today"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true
            onClicked: root.showToday()
          }

          Button {
            id: nextButton
            text: ">"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true
            onClicked: root.moveMonth(1)
          }
        }

        Grid {
          width: parent.width
          columns: 7
          rowSpacing: Style.spacing.xs
          columnSpacing: Style.spacing.xs

          Repeater {
            model: root.weekdayLabels
            delegate: Text {
              required property string modelData
              width: (calendarColumn.width - Style.spacing.xs * 6) / 7
              height: Style.space(24)
              text: modelData
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.45)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }

          Repeater {
            model: root.monthCells()
            delegate: Rectangle {
              required property var modelData
              width: (calendarColumn.width - Style.spacing.xs * 6) / 7
              height: Style.space(34)
              radius: Style.cornerRadius
              color: modelData.today
                ? Style.selectedFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent)
                : "transparent"
              border.color: modelData.today
                ? Style.selectedBorderFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent)
                : "transparent"
              border.width: modelData.today ? Math.max(1, Style.selectedBorderWidth) : 0

              Text {
                anchors.centerIn: parent
                text: modelData.day
                color: modelData.currentMonth
                  ? (root.bar ? root.bar.foreground : Color.foreground)
                  : Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.8)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                font.bold: modelData.today
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: Style.spacing.hairline
          color: Qt.rgba((root.bar ? root.bar.foreground : Color.foreground).r,
                         (root.bar ? root.bar.foreground : Color.foreground).g,
                         (root.bar ? root.bar.foreground : Color.foreground).b,
                         0.16)
        }

        Text {
          width: parent.width
          text: Qt.formatDate(root.displayDate, "dddd, dd MMMM yyyy")
          color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }
    }
  }
}
