import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../colors" as ColorsModule
import "../services" as Services

Item {
    id: detailView

    readonly property var c: ColorsModule.Colors
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontBody:    "Noto Sans"

    signal backRequested()
    signal chapterSelected(string chapterId)
    signal keyboardFocusRequested()

    // ── Library state ─────────────────────────────────────────────────────────
    readonly property bool _inLibrary:
        Services.Manga.currentManga ? Services.Manga.isInLibrary(Services.Manga.currentManga.id) : false

    // ── Filter / sort state ───────────────────────────────────────────────────
    property bool   _sortAscending:  false
    property string _chapterFilter:  ""

    function reset() {
        _chapterFilter  = ""
        _sortAscending  = false
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function scrollChaptersBy(pixels) {
        const maxY = Math.max(0, chapterList.contentHeight - chapterList.height)
        chapterList.contentY = clamp(chapterList.contentY + pixels, 0, maxY)
    }

    function selectChapter(index) {
        if (detailView._processedChapters.length === 0) return
        chapterList.currentIndex = clamp(index, 0, detailView._processedChapters.length - 1)
        chapterList.positionViewAtIndex(chapterList.currentIndex, ListView.Contain)
    }

    function activateSelectedChapter() {
        if (chapterList.currentIndex < 0 || chapterList.currentIndex >= detailView._processedChapters.length) return
        const chapter = detailView._processedChapters[chapterList.currentIndex]
        Services.Manga.fetchChapterPages(chapter.id)
        detailView.chapterSelected(chapter.id)
        if (Services.Manga.currentManga && Services.Manga.isInLibrary(Services.Manga.currentManga.id)) {
            Services.Manga.updateLastRead(Services.Manga.currentManga.id, chapter.id, chapter.chapter)
        }
    }

    function handleKey(event) {
        if (chapterSearch.activeFocus) {
            if (event.key === Qt.Key_Escape) {
                chapterSearch.focus = false
                keyboardFocusRequested()
                return true
            }
            return false
        }

        if (event.key === Qt.Key_H || event.key === Qt.Key_Backspace) {
            Services.Manga.clearChapterList()
            detailView.backRequested()
            return true
        }
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) { selectChapter(chapterList.currentIndex + 1); return true }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) { selectChapter(chapterList.currentIndex - 1); return true }
        if (event.key === Qt.Key_D) { scrollChaptersBy(chapterList.height * 0.55); return true }
        if (event.key === Qt.Key_U) { scrollChaptersBy(-chapterList.height * 0.55); return true }
        if (event.key === Qt.Key_F || event.key === Qt.Key_Space) { scrollChaptersBy(chapterList.height * 0.9); return true }
        if (event.key === Qt.Key_B) { scrollChaptersBy(-chapterList.height * 0.9); return true }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { activateSelectedChapter(); return true }
        if (event.key === Qt.Key_G && event.modifiers & Qt.ShiftModifier) { selectChapter(detailView._processedChapters.length - 1); return true }
        if (event.key === Qt.Key_G) { selectChapter(0); return true }
        if (event.key === Qt.Key_Slash || event.text === "/") { chapterSearch.forceActiveFocus(); return true }
        if (event.key === Qt.Key_S) { detailView._sortAscending = !detailView._sortAscending; return true }
        return false
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    function formatChapter(ch) {
        if (!ch) return "?"
        const match = ch.match(/\d+(\.\d+)?/)
        return match ? match[0] : ch
    }

    // ── Processed (filtered + sorted) chapter list ────────────────────────────
    readonly property var _processedChapters: {
        if (!Services.Manga.currentManga) return []
        let chapters = Services.Manga.currentManga.chapters.slice()

        if (detailView._chapterFilter.trim() !== "") {
            const f = detailView._chapterFilter.trim().toLowerCase()
            chapters = chapters.filter(ch => {
                const num   = detailView.formatChapter(ch.chapter).toLowerCase()
                const title = (ch.title || "").toLowerCase()
                return num.includes(f) || title.includes(f)
            })
        }

        chapters.sort((a, b) => {
            const numA = parseFloat(detailView.formatChapter(a.chapter)) || 0
            const numB = parseFloat(detailView.formatChapter(b.chapter)) || 0
            return detailView._sortAscending ? numA - numB : numB - numA
        })

        return chapters
    }

    // ═════════════════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: c.surface_container_low
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: c.outline_variant; opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 10 }
                spacing: 2

                // ── Back button ───────────────────────────────────────────────
                Item {
                    width: 44; height: 44

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34; height: 34; radius: 17
                        color: backArea.containsMouse ? c.surface_container : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "←"; font.pixelSize: 18; color: c.on_surface_variant
                    }
                    MouseArea {
                        id: backArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            Services.Manga.clearChapterList()
                            detailView.backRequested()
                            detailView.keyboardFocusRequested()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.Manga.currentManga ? Services.Manga.currentManga.title : ""
                    font.family: detailView.fontDisplay
                    font.pixelSize: 15; color: c.on_surface; elide: Text.ElideRight
                }

                // ── Library toggle ────────────────────────────────────────────
                Item {
                    visible: Services.Manga.currentManga !== null
                    width: libBtnLabel.implicitWidth + 28
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: detailView._inLibrary ? c.primary_container : c.surface_container
                        border.color: detailView._inLibrary ? c.primary : c.outline_variant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailView._inLibrary ? "✓" : "+"
                            font.pixelSize: 11; font.bold: true
                            color: detailView._inLibrary ? c.on_primary_container : c.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            id: libBtnLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Library"
                            font.family: detailView.fontBody
                            font.pixelSize: 11; font.letterSpacing: 0.3
                            color: detailView._inLibrary ? c.on_primary_container : c.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (detailView._inLibrary)
                                Services.Manga.removeFromLibrary(Services.Manga.currentManga.id)
                            else
                                Services.Manga.addToLibrary({
                                    id:       Services.Manga.currentManga.id,
                                    title:    Services.Manga.currentManga.title,
                                    coverUrl: Services.Manga.currentManga.coverUrl
                                })
                            detailView.keyboardFocusRequested()
                        }
                    }
                }
            }
        }

        // ── Hero banner ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Services.Manga.currentManga !== null ? 160 : 0
            clip: true
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Blurred cover background
            Image {
                anchors.fill: parent
                source: Services.Manga.currentManga ? Services.Manga.currentManga.coverUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; opacity: 0.2
            }

            // Gradient overlay
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(c.surface_container_low.r, c.surface_container_low.g, c.surface_container_low.b, 0.8) }
                    GradientStop { position: 1.0; color: c.background }
                }
            }

            // Content row
            Row {
                anchors { fill: parent; margins: 14 }
                spacing: 14

                // Cover thumbnail
                Rectangle {
                    width: 90; height: 130; radius: 8
                    color: c.surface_container_high; clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: Services.Manga.currentManga ? Services.Manga.currentManga.coverUrl : ""
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 8; color: "transparent"
                        border.color: c.outline_variant; border.width: 1
                    }
                }

                Column {
                    width: parent.width - 104
                    spacing: 6; anchors.verticalCenter: parent.verticalCenter

                    // Status badge
                    Rectangle {
                        visible: Services.Manga.currentManga && Services.Manga.currentManga.status.length > 0
                        height: 18; width: statusText.implicitWidth + 14; radius: 9
                        color: Qt.rgba(c.tertiary.r, c.tertiary.g, c.tertiary.b, 0.15)
                        border.color: c.tertiary; border.width: 1

                        Text {
                            id: statusText; anchors.centerIn: parent
                            text: Services.Manga.currentManga ? (Services.Manga.currentManga.status || "").toUpperCase() : ""
                            font.family: detailView.fontBody
                            font.pixelSize: 9; font.letterSpacing: 1.2; font.bold: true
                            color: c.tertiary
                        }
                    }

                    // Author
                    Text {
                        width: parent.width
                        text: Services.Manga.currentManga ? (Services.Manga.currentManga.authors || []).join(", ") : ""
                        font.family: detailView.fontBody
                        font.pixelSize: 12; font.bold: true
                        color: c.on_surface; elide: Text.ElideRight
                    }

                    // Description
                    Text {
                        width: parent.width
                        text: Services.Manga.currentManga ? Services.Manga.currentManga.description : ""
                        font.family: detailView.fontBody; font.pixelSize: 11
                        color: c.on_surface_variant
                        wrapMode: Text.Wrap; maximumLineCount: 3
                        elide: Text.ElideRight; opacity: 0.8; lineHeight: 1.35
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: c.outline_variant; opacity: 0.35
            }
        }

        // ── Chapter count + last-read strip ───────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 36
            color: c.surface_container
            visible: Services.Manga.currentManga !== null

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }

                Text {
                    text: Services.Manga.currentManga ? Services.Manga.currentManga.chapters.length + " chapters" : ""
                    font.family: detailView.fontBody
                    font.pixelSize: 11; font.letterSpacing: 1
                    color: c.on_surface_variant; opacity: 0.75
                }

                Item { Layout.fillWidth: true }

                // Last-read badge
                Rectangle {
                    readonly property var _entry: Services.Manga.currentManga
                        ? Services.Manga.getLibraryEntry(Services.Manga.currentManga.id) : null
                    visible: _entry !== null && _entry !== undefined
                        && _entry.lastReadChapterNum !== ""
                        && _entry.lastReadChapterNum !== undefined
                    height: 20; width: lastReadText.implicitWidth + 18; radius: 10
                    color: Qt.rgba(c.primary.r, c.primary.g, c.primary.b, 0.12)
                    border.color: c.primary; border.width: 1

                    Text {
                        id: lastReadText; anchors.centerIn: parent
                        text: {
                            var e = Services.Manga.currentManga
                                ? Services.Manga.getLibraryEntry(Services.Manga.currentManga.id) : null
                            return e ? "Last: Ch. " + detailView.formatChapter(e.lastReadChapterNum) : ""
                        }
                        font.family: detailView.fontBody
                        font.pixelSize: 9; font.letterSpacing: 0.8; color: c.primary
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: c.outline_variant; opacity: 0.3
            }
        }

        // ── Search & Sort bar ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 56
            color: c.surface_container_low
            visible: Services.Manga.currentManga !== null

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 8

                // Search pill
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 18
                    color: c.surface_container
                    border.width: 1
                    border.color: chapterSearch.activeFocus ? c.primary : Qt.rgba(c.outline.r, c.outline.g, c.outline.b, 0.2)
                    Behavior on border.color { ColorAnimation { duration: 130 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
                        spacing: 6

                        Text {
                            text: "⌕"
                            font.pixelSize: 16
                            color: c.primary; opacity: 0.7
                        }

                        TextInput {
                            id: chapterSearch
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            font.family: detailView.fontBody
                            font.pixelSize: 12
                            color: c.on_surface
                            selectionColor: Qt.rgba(c.primary.r, c.primary.g, c.primary.b, 0.35)
                            clip: true

                            // Placeholder text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Filter chapters…"
                                font.family: detailView.fontBody
                                font.pixelSize: 12
                                color: c.on_surface_variant
                                opacity: 0.45
                                visible: chapterSearch.text === "" && !chapterSearch.activeFocus
                            }

                            onTextChanged: detailView._chapterFilter = text
                        }

                        // Clear button — only shown when there is text
                        Item {
                            width: visible ? 28 : 0; height: 28
                            visible: detailView._chapterFilter !== ""

                            Rectangle {
                                anchors.centerIn: parent
                                width: 22; height: 22; radius: 11
                                color: clearArea.containsMouse
                                    ? Qt.rgba(c.on_surface.r, c.on_surface.g, c.on_surface.b, 0.12)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "✕"; font.pixelSize: 11
                                color: c.on_surface_variant
                            }
                            MouseArea {
                                id: clearArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    detailView._chapterFilter = ""
                                    chapterSearch.text = ""
                                }
                            }
                        }
                    }
                }

                // Sort toggle button
                Item {
                    width: 36; height: 36

                    Rectangle {
                        anchors.fill: parent; radius: 18
                        color: sortArea.containsMouse
                            ? c.primary_container
                            : Qt.rgba(c.primary_container.r, c.primary_container.g, c.primary_container.b, 0.6)
                        border.color: c.primary; border.width: 1
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: detailView._sortAscending ? "↑" : "↓"
                        font.pixelSize: 16; font.bold: true
                        color: c.on_primary_container
                    }
                    MouseArea {
                        id: sortArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            detailView._sortAscending = !detailView._sortAscending
                            detailView.keyboardFocusRequested()
                        }

                        ToolTip.visible: containsMouse
                        ToolTip.delay: 600
                        ToolTip.text: detailView._sortAscending ? "Sort: Ascending" : "Sort: Descending"
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: c.outline_variant; opacity: 0.3
            }
        }

        // ── Chapter list ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            Rectangle { anchors.fill: parent; color: c.background }

            // Loading overlay
            Rectangle {
                anchors.fill: parent; color: c.background
                visible: Services.Manga.isFetchingDetail; z: 5

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: c.primary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching chapters"
                        color: c.on_surface_variant
                        font.family: detailView.fontBody
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.7
                    }
                }
            }

            ListView {
                id: chapterList
                anchors.fill: parent; clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: detailView._processedChapters   // ← filtered + sorted
                maximumFlickVelocity: 9000
                flickDeceleration: 2400

                onCountChanged: detailView.selectChapter(Math.min(Math.max(currentIndex, 0), count - 1))

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        detailView.scrollChaptersBy(-event.angleDelta.y * 2.8)
                        event.accepted = true
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3; color: c.primary; opacity: 0.45; radius: 2
                    }
                }

                delegate: Rectangle {
                    width: chapterList.width; height: 58

                    readonly property var _libEntry: Services.Manga.currentManga
                        ? Services.Manga.getLibraryEntry(Services.Manga.currentManga.id) : null
                    readonly property bool isLastRead:
                        _libEntry !== null && _libEntry !== undefined
                        && _libEntry.lastReadChapterId === modelData.id

                    color: isLastRead
                        ? Qt.rgba(c.primary.r, c.primary.g, c.primary.b, 0.07)
                        : (chapterRowArea.pressed
                            ? c.surface_container_high
                            : (chapterList.currentIndex === index
                                ? Qt.rgba(c.primary.r, c.primary.g, c.primary.b, 0.1)
                                : (chapterRowArea.containsMouse ? c.surface_container : "transparent")))
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left; right: parent.right
                            leftMargin: 72; rightMargin: 16
                        }
                        height: 1; color: c.outline_variant; opacity: 0.25
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 14

                        // Chapter number pill
                        Rectangle {
                            width: chapterPillText.implicitWidth + 16
                            height: 26; radius: 13
                            color: isLastRead ? c.primary : c.primary_container

                            Text {
                                id: chapterPillText; anchors.centerIn: parent
                                text: "Ch." + detailView.formatChapter(modelData.chapter)
                                font.family: detailView.fontBody
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5
                                color: isLastRead ? c.on_primary : c.on_primary_container
                            }
                        }

                        Column {
                            Layout.fillWidth: true; spacing: 3

                            Text {
                                width: parent.width
                                text: modelData.title || ("Chapter " + detailView.formatChapter(modelData.chapter))
                                font.family: detailView.fontBody
                                font.pixelSize: 12; color: c.on_surface; elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.publishAt
                                    ? Qt.formatDate(new Date(modelData.publishAt), "MMM d, yyyy")
                                    : ""
                                font.family: detailView.fontBody
                                font.pixelSize: 10; color: c.on_surface_variant
                                opacity: 0.55; font.letterSpacing: 0.3
                            }
                        }

                        Text {
                            text: "›"; font.pixelSize: 20; color: c.outline
                            opacity: chapterRowArea.containsMouse ? 0.9 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }

                    MouseArea {
                        id: chapterRowArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            detailView.selectChapter(index)
                            Services.Manga.fetchChapterPages(modelData.id)
                            detailView.chapterSelected(modelData.id)
                            detailView.keyboardFocusRequested()
                            if (Services.Manga.currentManga && Services.Manga.isInLibrary(Services.Manga.currentManga.id)) {
                                Services.Manga.updateLastRead(
                                    Services.Manga.currentManga.id,
                                    modelData.id,
                                    modelData.chapter
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
