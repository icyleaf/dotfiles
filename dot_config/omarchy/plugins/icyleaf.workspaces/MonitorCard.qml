import QtQuick
import qs.Commons
import qs.Ui

// A single monitor card in the Per-Monitor Layout Preview Overlay.
//
// Purely presentational: receives a precomputed card model (window rectangles
// in card-local coordinates, a 10-slot occupancy strip, header text) and
// renders it. All geometry is computed by the LayoutModel seam.
Rectangle {
  id: root

  required property var cardModel
  property bool selected: false
  property string fontFamily: Style.font.family

  readonly property int chromePadding: Math.max(2, Math.round(Style.spacing.xs))

  color: cardModel.focused
    ? Color.menu.background
    : Util.alpha(Color.menu.background, cardModel.empty ? 0.55 : 0.8)
  radius: Style.cornerRadius
  border.width: (cardModel.focused || selected) ? Math.max(1, Style.focusBorderWidth) : 1
  border.color: cardModel.focused
    ? Color.accent
    : (selected ? Util.alpha(Color.accent, 0.6) : Util.alpha(Color.menu.border, 0.2))
  clip: true

  signal activated(int monitorId)

  HoverHandler {
    id: cardHover
    cursorShape: Qt.PointingHandCursor
  }

  // Whole-card click → focus this monitor and close. Sits below inner chrome.
  MouseArea {
    anchors.fill: parent
    z: 1
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated(cardModel.id)
  }

  // Faint centered hint for an idle active workspace.
  Text {
    visible: cardModel.empty
    z: 2
    anchors.centerIn: parent
    text: "\u00B7"
    color: Color.menu.text
    opacity: cardModel.focused ? 0.35 : 0.16
    font.family: fontFamily
    font.pixelSize: Style.font.displayLarge
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
  }

  // ── Window projection (card-local from LayoutModel seam) ─────────────────
  // Occupies the whole card; header and strip float above with translucent
  // backgrounds so the layout under them stays visible.
  Repeater {
    model: cardModel.windows
    z: 3

    Rectangle {
      required property var modelData
      required property int index

      readonly property bool isGroup: modelData.groupSize > 1

      x: modelData.x
      y: modelData.y
      width: modelData.width
      height: modelData.height
      color: "transparent"
      border.width: Math.max(1, Style.space(1))
      border.color: isGroup
        ? (index === root.hoveredIndex ? Color.accent : Util.alpha(Color.accent, 0.85))
        : (index === root.hoveredIndex ? Color.menu.text : Util.alpha(Color.menu.text, 0.5))
      radius: Math.max(2, Style.space(2))

      Rectangle {
        visible: isGroup
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Math.max(1, Style.space(1))
        width: groupChip.implicitWidth + Style.space(4)
        height: groupChip.implicitHeight + Style.space(1)
        radius: Math.max(2, Style.space(2))
        color: Util.alpha(Color.menu.background, 0.8)
        border.width: 1
        border.color: Util.alpha(Color.accent, 0.5)

        Text {
          id: groupChip
          anchors.centerIn: parent
          text: "\u25A0 " + modelData.groupSize
          font.family: fontFamily
          font.pixelSize: Style.font.caption
          color: Color.menu.text
        }
      }

      MouseArea {
        id: winHover
        anchors.fill: parent
        z: 20
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated(cardModel.id)
        onEntered: root.hoveredIndex = index
        onExited: if (root.hoveredIndex === index) root.hoveredIndex = -1
      }

      Rectangle {
        id: titlePill
        visible: winHover.containsMouse
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(1, Style.space(1))
        width: Math.min(parent.width - Style.space(2), titleText.implicitWidth + Style.space(8))
        height: titleText.implicitHeight + Style.space(2)
        radius: height / 2
        color: Util.alpha(Color.menu.background, 0.92)
        border.width: 1
        border.color: Util.alpha(Color.menu.border, 0.15)

        Text {
          id: titleText
          anchors.centerIn: parent
          text: modelData.title
          font.family: fontFamily
          font.pixelSize: Style.font.caption
          color: Color.menu.text
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }

  readonly property string resLabel: {
    var pw = cardModel.physicalWidth
    var ph = cardModel.physicalHeight
    var sc = cardModel.scale
    var res = (pw && ph) ? (pw + "x" + ph) : ""
    var scaled = (sc && sc !== 1) ? ("@" + (Math.round(sc * 100) / 100)) : ""
    return (res + scaled)
  }

  // ── Header pill (compact, floats top-left over the window canvas) ────────
  // Unlike a full-width banner this never covers the window layout: it is a
  // small translucent capsule anchored to the top edge, leaving the rest of
  // the card for the workspace preview.
  Rectangle {
    id: headerPill
    z: 10
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: Math.max(1, Style.space(1))
    implicitWidth: headerContent.implicitWidth + chromePadding * 2
    implicitHeight: headerContent.implicitHeight + Math.max(1, Style.space(1)) * 2
    radius: height / 2
    color: Util.alpha(Color.menu.background, cardModel.focused ? 0.95 : 0.8)
    border.width: cardModel.focused ? 1 : 0
    border.color: Util.alpha(Color.accent, 0.5)
    width: Math.min(implicitWidth, parent.width - chromePadding * 2)

    Row {
      id: headerContent
      anchors.centerIn: parent
      spacing: Style.space(3)

      Text {
        text: cardModel.badgeText
        font.family: fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        color: cardModel.focused ? Color.accent : Util.alpha(Color.menu.text, 0.9)
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        text: cardModel.name
        font.family: fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        color: cardModel.focused ? Color.menu.text : Util.alpha(Color.menu.text, 0.85)
        elide: Text.ElideRight
        width: headerPill.width - chromePadding * 2 - headerContent.spacing * 3 - resText.implicitWidth
        visible: headerPill.width > 120
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        id: resText
        text: root.resLabel
        font.family: fontFamily
        font.pixelSize: Style.font.caption
        color: Util.alpha(Color.menu.text, 0.55)
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  // ── Card tooltip: full description + resolution (hover) ──────────────────
  Rectangle {
    id: cardTooltip
    z: 30
    visible: cardHover.containsMouse && (cardModel.description !== "" || root.resLabel !== "")
    anchors.top: parent.top
    anchors.topMargin: headerPill.height + Style.space(1)
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(parent.width - chromePadding * 2, cardTooltipText.implicitWidth + Style.space(8))
    height: cardTooltipText.implicitHeight + Style.space(2)
    radius: Math.max(2, Style.space(2))
    color: Util.alpha(Color.menu.background, 0.94)
    border.width: 1
    border.color: Util.alpha(Color.menu.border, 0.15)

    Text {
      id: cardTooltipText
      anchors.centerIn: parent
      text: cardModel.description
      font.family: fontFamily
      font.pixelSize: Style.font.caption
      color: Color.menu.text
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  // ── Occupancy strip (floating at bottom) ─────────────────────────────────
  Row {
    id: slotStrip
    z: 10
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: chromePadding
    anchors.rightMargin: chromePadding
    anchors.bottomMargin: Math.max(1, Style.space(1))
    spacing: Math.max(1, Style.space(1))

    Repeater {
      model: cardModel.slots

      Rectangle {
        required property var modelData

        readonly property bool isFocused: modelData.focused
        readonly property bool isActive: modelData.active
        readonly property bool isOccupied: modelData.occupied

        width: (slotStrip.width - slotStrip.spacing * (slotStrip.count - 1)) / Math.max(1, slotStrip.count)
        height: Math.max(3, Style.space(3))
        radius: height / 2
        color: isFocused ? Color.accent
          : (isActive ? Util.alpha(Color.accent, 0.8)
             : (isOccupied ? Util.alpha(Color.menu.text, 0.5)
                : Util.alpha(Color.menu.text, 0.12)))
        border.width: isFocused ? Math.max(1, Style.space(1)) : 0
        border.color: Util.alpha(Color.menu.scrim, 0.5)
      }
    }
  }

  property int hoveredIndex: -1
}
