import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../colors" as ColorsModule
import "../services" as Services

Item {
    id: browseView

    // ── Exposed API ──────────────────────────────────────────────────────────
    readonly property var c: ColorsModule.Colors
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontBody:    "Noto Sans"

    // Emitted when the user taps a manga card
    signal mangaSelected(string mangaId)
    signal keyboardFocusRequested()

    property string currentTagId: ""
    property int selectedIndex: 0

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function selectIndex(index) {
        if (Services.Manga.mangaList.length === 0) return
        selectedIndex = clamp(index, 0, Services.Manga.mangaList.length - 1)
        mangaGrid.currentIndex = selectedIndex
        mangaGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= Services.Manga.mangaList.length) return
        const entry = Services.Manga.mangaList[selectedIndex]
        Services.Manga.fetchMangaDetail(entry.id)
        browseView.mangaSelected(entry.id)
    }

    function selectTag(delta) {
        const tags = ["", "latest", "ja", "ko", "zh"]
        let next = tags.indexOf(currentTagId)
        next = clamp((next < 0 ? 0 : next) + delta, 0, tags.length - 1)
        currentTagId = tags[next]
        searchField.text = ""
        searchBar.visible = false
        Services.Manga.fetchByOrigin(currentTagId, true)
    }

    function handleKey(event) {
        if (searchField.activeFocus) {
            if (event.key === Qt.Key_Escape) {
                searchField.focus = false
                searchBar.visible = false
                keyboardFocusRequested()
                return true
            }
            return false
        }

        const columns = Math.max(1, Math.floor(mangaGrid.width / mangaGrid.cellWidth))
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) { selectIndex(selectedIndex + columns); return true }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) { selectIndex(selectedIndex - columns); return true }
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) { selectIndex(selectedIndex - 1); return true }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) { selectIndex(selectedIndex + 1); return true }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { activateSelected(); return true }
        if (event.key === Qt.Key_G && event.modifiers & Qt.ShiftModifier) { selectIndex(Services.Manga.mangaList.length - 1); return true }
        if (event.key === Qt.Key_G) { selectIndex(0); return true }
        if (event.key === Qt.Key_Slash || event.text === "/") {
            searchBar.visible = !searchBar.visible
            if (searchBar.visible) {
                searchField.forceActiveFocus()
            } else {
                searchField.text = ""
                Services.Manga.fetchByOrigin(browseView.currentTagId, true)
                keyboardFocusRequested()
            }
            return true
        }
        if (event.key === Qt.Key_BracketLeft) { selectTag(-1); return true }
        if (event.key === Qt.Key_BracketRight) { selectTag(1); return true }
        return false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: c.surface_container_low
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: c.outline_variant
                opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 12 }
                spacing: 10

                // Wordmark
                Row {
                    spacing: 0
                    visible: !searchBar.visible
                    Layout.fillWidth: true

                    Text {
                        text: "M"
                        font.family: browseView.fontDisplay
                        font.pixelSize: 24
                        font.letterSpacing: 1
                        color: c.primary
                    }
                    Text {
                        text: "anga"
                        font.family: browseView.fontDisplay
                        font.pixelSize: 24
                        font.letterSpacing: 1
                        color: c.on_surface
                        opacity: 0.85
                    }
                }

                // Search bar
                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    height: 38
                    radius: 19
                    color: c.surface_container
                    visible: false
                    border.color: searchField.activeFocus ? c.primary : c.outline_variant
                    border.width: searchField.activeFocus ? 1.5 : 1
                    Behavior on border.width { NumberAnimation { duration: 120 } }

                    TextInput {
                        id: searchField
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; right: clearBtn.left
                            leftMargin: 16; rightMargin: 6
                        }
                        color: c.on_surface
                        font.family: browseView.fontBody
                        font.pixelSize: 13
                        clip: true
                        onTextChanged: searchDebounce.restart()
                        Keys.onEscapePressed: {
                            searchBar.visible = false
                            text = ""
                            Services.Manga.fetchByOrigin(browseView.currentTagId, true)
                        }
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 16 }
                        text: "Search titles…"
                        color: c.on_surface_variant
                        font.family: browseView.fontBody
                        font.pixelSize: 13
                        visible: searchField.text.length === 0
                        opacity: 0.6
                    }

                    // Clear button
                    Item {
                        id: clearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                        width: 22; height: 22
                        visible: searchField.text.length > 0
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18; height: 18; radius: 9
                            color: c.surface_container_highest
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: c.on_surface_variant
                            font.pixelSize: 9
                            font.bold: true
                        }
                        MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 350
                    onTriggered: {
                        if (searchField.text.trim().length > 0)
                            Services.Manga.searchManga(searchField.text.trim(), true)
                        else
                            Services.Manga.fetchByOrigin(browseView.currentTagId, true)
                    }
                }

                // Search toggle button
                Item {
                    width: 40; height: 40

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34; height: 34; radius: 17
                        color: searchBar.visible ? c.primary_container : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⌕"
                        font.pixelSize: 19
                        color: searchBar.visible ? c.on_primary_container : c.on_surface_variant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchBar.visible = !searchBar.visible
                            if (searchBar.visible) {
                                searchField.forceActiveFocus()
                            } else {
                                searchField.text = ""
                                Services.Manga.fetchByOrigin(browseView.currentTagId, true)
                                browseView.keyboardFocusRequested()
                            }
                        }
                    }
                }
            }
        }

        // ── Tag filter chips ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: c.surface_container_low
            clip: true

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: c.outline_variant
                opacity: 0.25
            }

            ListView {
                id: tagList
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                orientation: ListView.Horizontal
                spacing: 7
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: ListModel {
                    ListElement { label: "Hot";     tagId: ""       }
                    ListElement { label: "Latest";  tagId: "latest" }
                    ListElement { label: "Manga";   tagId: "ja"     }
                    ListElement { label: "Manhwa";  tagId: "ko"     }
                    ListElement { label: "Manhua";  tagId: "zh"     }
                }

                delegate: Item {
                    width: chip.implicitWidth + 28
                    height: tagList.height

                    Rectangle {
                        id: chip
                        anchors.centerIn: parent
                        implicitWidth: chipLabel.implicitWidth + 28
                        height: 30
                        radius: 15
                        color: browseView.currentTagId === tagId
                            ? c.primary
                            : c.surface_container
                        border.color: browseView.currentTagId === tagId
                            ? c.primary
                            : c.outline_variant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: label
                            font.family: browseView.fontBody
                            font.pixelSize: 12
                            font.letterSpacing: 0.6
                            color: browseView.currentTagId === tagId
                                ? c.on_primary
                                : c.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            browseView.currentTagId = tagId
                            searchField.text = ""
                            searchBar.visible = false
                            Services.Manga.fetchByOrigin(tagId, true)
                            browseView.keyboardFocusRequested()
                        }
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: c.outline_variant
                opacity: 0.3
            }
        }

        // ── Main content area ────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Backend startup/error state
            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: !Services.Manga.serverReady
                    && Services.Manga.mangaList.length === 0
                    && Services.Manga.mangaError.length === 0
                z: 20

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 360)
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: Services.Manga.serverError.length > 0 ? c.error : c.primary
                        border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 900
                            loops: Animation.Infinite
                            running: parent.visible && Services.Manga.serverError.length === 0
                            easing.type: Easing.Linear
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Services.Manga.statusMessage
                        color: Services.Manga.serverError.length > 0 ? c.error : c.on_surface_variant
                        font.family: browseView.fontBody
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: Services.Manga.serverError.length > 0
                        text: "Install missing Python modules or check whether port 5150 is already in use."
                        color: c.on_surface_variant
                        opacity: 0.72
                        font.family: browseView.fontBody
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Loading state
            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: Services.Manga.isFetchingManga && Services.Manga.mangaList.length === 0
                z: 10

                Column {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: c.primary
                        border.width: 2.5
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite
                            running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "loading"
                        color: c.on_surface_variant
                        font.family: browseView.fontBody
                        font.pixelSize: 11
                        font.letterSpacing: 2.5
                        opacity: 0.7
                    }
                }
            }

            // Error state
            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: Services.Manga.mangaError.length > 0 && !Services.Manga.isFetchingManga
                z: 9

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        text: "⚠"
                        font.pixelSize: 32
                        color: c.error
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.8
                    }
                    Text {
                        text: Services.Manga.mangaError
                        color: c.on_surface_variant
                        font.pixelSize: 12
                        font.family: browseView.fontBody
                        wrapMode: Text.Wrap
                        width: 260
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.4
                    }
                }
            }

            // ── Manga grid ───────────────────────────────────────────────────
            GridView {
                id: mangaGrid
                anchors.fill: parent
                anchors.margins: 10
                cellWidth: (width - 10) / 4
                cellHeight: cellWidth * 1.58
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Services.Manga.mangaList
                currentIndex: browseView.selectedIndex
                maximumFlickVelocity: 8000
                flickDeceleration: 2600

                onCountChanged: browseView.selectIndex(Math.min(browseView.selectedIndex, count - 1))

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        color: c.primary
                        opacity: 0.45
                        radius: 2
                    }
                }

                onContentYChanged: {
                    if (contentY + height > contentHeight - cellHeight * 2)
                        Services.Manga.fetchNextMangaPage()
                }

                delegate: Item {
                    width: mangaGrid.cellWidth
                    height: mangaGrid.cellHeight

                    Rectangle {
                        id: card
                        anchors { fill: parent; margins: 5 }
                        radius: 12
                        color: c.surface_container
                        clip: true

                        // Cover image
                        Image {
                            id: coverImg
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height - titleBar.height
                            source: modelData.thumbUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            // Placeholder shimmer
                            Rectangle {
                                anchors.fill: parent
                                color: c.surface_container_high
                                visible: coverImg.status !== Image.Ready
                                Text {
                                    anchors.centerIn: parent
                                    text: "◫"
                                    font.pixelSize: 32
                                    color: c.outline
                                    opacity: 0.25
                                }
                            }

                            // Gradient vignette at bottom of cover
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 56
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: c.surface_container }
                                }
                            }
                        }

                        // Title bar
                        Rectangle {
                            id: titleBar
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: titleText.implicitHeight + 18
                            color: c.surface_container
                            radius: 12

                            Text {
                                id: titleText
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10; rightMargin: 10
                                }
                                text: modelData.title || ""
                                font.family: browseView.fontBody
                                font.pixelSize: 11
                                font.letterSpacing: 0.2
                                color: c.on_surface
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                lineHeight: 1.3
                            }
                        }

                        // Hover + press overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: c.primary
                            opacity: cardArea.pressed
                                ? 0.16
                                : (mangaGrid.currentIndex === index ? 0.12 : (cardArea.containsMouse ? 0.07 : 0))
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            border.width: mangaGrid.currentIndex === index ? 2 : 0
                            border.color: c.primary
                            opacity: 0.9
                        }

                        // Scale effect on hover
                        transform: Scale {
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            xScale: cardArea.pressed ? 0.97 : 1.0
                            yScale: cardArea.pressed ? 0.97 : 1.0
                            Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                browseView.selectIndex(index)
                                Services.Manga.fetchMangaDetail(modelData.id)
                                browseView.mangaSelected(modelData.id)
                                browseView.keyboardFocusRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}
