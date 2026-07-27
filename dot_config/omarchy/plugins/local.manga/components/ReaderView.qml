import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../colors" as ColorsModule
import "../services" as Services

Item {
    id: readerView

    // ── Exposed API ──────────────────────────────────────────────────────────
    readonly property var c: ColorsModule.Colors
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontBody:    "Noto Sans"

    // Emitted when the user navigates back
    signal backRequested()
    signal keyboardFocusRequested()

    // ── Internal state ───────────────────────────────────────────────────────
    property bool headerVisible: true

    // Called by the parent to reset state when re-entering this view
    function reset() {
        headerVisible = true
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function scrollPagesBy(pixels) {
        const maxY = Math.max(0, pageListView.contentHeight - pageListView.height)
        pageListView.contentY = clamp(pageListView.contentY + pixels, 0, maxY)
    }

    function handleKey(event) {
        if (event.key === Qt.Key_H || event.key === Qt.Key_Backspace) {
            Services.Manga.clearChapterPages()
            readerView.backRequested()
            return true
        }
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) { scrollPagesBy(240); return true }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) { scrollPagesBy(-240); return true }
        if (event.key === Qt.Key_D) { scrollPagesBy(pageListView.height * 0.58); return true }
        if (event.key === Qt.Key_U) { scrollPagesBy(-pageListView.height * 0.58); return true }
        if (event.key === Qt.Key_F || event.key === Qt.Key_Space) { scrollPagesBy(pageListView.height * 0.92); return true }
        if (event.key === Qt.Key_B) { scrollPagesBy(-pageListView.height * 0.92); return true }
        if (event.key === Qt.Key_G && event.modifiers & Qt.ShiftModifier) { pageListView.positionViewAtEnd(); return true }
        if (event.key === Qt.Key_G) { pageListView.positionViewAtBeginning(); return true }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            readerView.headerVisible = !readerView.headerVisible
            return true
        }
        return false
    }

    // ── Ink-black background ─────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: "#08080a" }

    // ── Reader header ────────────────────────────────────────────────────────
    Rectangle {
        id: readerHeader
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 54
        color: Qt.rgba(0.05, 0.05, 0.08, 0.95)
        z: 10
        opacity: readerView.headerVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Bottom hairline
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 6; rightMargin: 16 }
            spacing: 2

            // Back button
            Item {
                width: 44; height: 44

                Rectangle {
                    anchors.centerIn: parent
                    width: 34; height: 34; radius: 17
                    color: readerBackArea.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.1)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "←"
                    font.pixelSize: 18
                    color: Qt.rgba(1, 1, 1, 0.7)
                }
                MouseArea {
                    id: readerBackArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Services.Manga.clearChapterPages()
                        readerView.backRequested()
                        readerView.keyboardFocusRequested()
                    }
                }
            }

            // Title
            Text {
                Layout.fillWidth: true
                text: Services.Manga.currentManga ? Services.Manga.currentManga.title : ""
                font.family: readerView.fontDisplay
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.85)
                elide: Text.ElideRight
            }

            // Page counter badge
            Rectangle {
                visible: Services.Manga.chapterPages.length > 0
                height: 24
                width: pageCountText.implicitWidth + 18
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.09)
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                Text {
                    id: pageCountText
                    anchors.centerIn: parent
                    text: (pageListView.currentIndex + 1) + " / " + Services.Manga.chapterPages.length
                    font.family: readerView.fontBody
                    font.pixelSize: 10
                    font.letterSpacing: 0.5
                    color: Qt.rgba(1, 1, 1, 0.65)
                }
            }
        }
    }

    // ── Fetching pages overlay ───────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#08080a"
        visible: Services.Manga.isFetchingPages
        z: 8

        Column {
            anchors.centerIn: parent
            spacing: 16

            Rectangle {
                width: 40; height: 40; radius: 20
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                border.color: c.primary; border.width: 2.5
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite
                    running: parent.visible
                    easing.type: Easing.Linear
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "loading pages"
                color: Qt.rgba(1, 1, 1, 0.4)
                font.family: readerView.fontBody
                font.pixelSize: 11
                font.letterSpacing: 2.5
            }
        }
    }

    // ── Pages error overlay ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#08080a"
        visible: Services.Manga.pagesError.length > 0 && !Services.Manga.isFetchingPages
        z: 7

        Column {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: "⚠"
                font.pixelSize: 32
                color: c.error
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.85
            }
            Text {
                text: Services.Manga.pagesError
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
                font.family: readerView.fontBody
                wrapMode: Text.Wrap
                width: 260
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.4
            }
        }
    }

    // ── Page list ────────────────────────────────────────────────────────────
    ListView {
        id: pageListView
        anchors {
            fill: parent
            topMargin: readerView.headerVisible ? 54 : 0
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Services.Manga.chapterPages
        spacing: 3
        maximumFlickVelocity: 11000
        flickDeceleration: 2200
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(event) {
                readerView.scrollPagesBy(-event.angleDelta.y * 3.2)
                event.accepted = true
            }
        }

        // Tap anywhere to toggle header
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                readerView.headerVisible = !readerView.headerVisible
                readerView.keyboardFocusRequested()
                mouse.accepted = false
            }
        }

        delegate: Item {
            width: pageListView.width
            height: pageImg.implicitHeight > 0
                ? pageImg.implicitHeight * (pageListView.width / pageImg.implicitWidth)
                : pageListView.width * 1.42

            Image {
                id: pageImg
                anchors.fill: parent
                source: modelData.url || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 350 } }

                // Loading placeholder
                Rectangle {
                    anchors.fill: parent
                    color: "#111115"
                    visible: pageImg.status !== Image.Ready

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            border.width: 1.5
                            RotationAnimator on rotation {
                                from: 0; to: 360; duration: 1200
                                loops: Animation.Infinite
                                running: parent.visible
                                easing.type: Easing.Linear
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "p. " + (modelData.index + 1)
                            color: Qt.rgba(1, 1, 1, 0.2)
                            font.pixelSize: 10
                            font.family: readerView.fontBody
                            font.letterSpacing: 1.5
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 2
                color: c.primary
                opacity: 0.35
                radius: 1
            }
        }
    }

    // ── Reading progress bar (bottom) ─────────────────────────────────────────
    Item {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 3
        z: 9
        visible: Services.Manga.chapterPages.length > 0

        // Track
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // Fill
        Rectangle {
            width: Services.Manga.chapterPages.length > 0
                ? parent.width * ((pageListView.currentIndex + 1) / Services.Manga.chapterPages.length)
                : 0
            height: parent.height
            color: c.primary
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }
    }
}
