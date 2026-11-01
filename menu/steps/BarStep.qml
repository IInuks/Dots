import QtQuick
import ".."
import "../components"

// "Bars" tab: pick a bar. Left 25 %: search field + list of every bar in
// bars/ (blue selection, hover, ↑/↓). Right 75 %: name, large preview,
// description. Typing goes straight into the search field.
FocusScope {
    id: page

    readonly property var bars: BarsModel.barNames
    readonly property string shown: Wizard.selectedBar

    // Search: matches name or README title, case-insensitive. Rows that
    // don't match are only hidden -- swapping the model would destroy
    // delegates whose BarTheme JSON may still be loading (crash, see
    // cacheBuffer below).
    property string query: ""
    readonly property string needle: query.trim().toLowerCase()
    function matches(name: string): bool {
        return needle.length === 0
            || name.toLowerCase().includes(needle)
            || BarInfo.titleOf(name).toLowerCase().includes(needle);
    }
    readonly property var hits: bars.filter(n => matches(n))

    onHitsChanged: {
        if (hits.length && hits.indexOf(Wizard.selectedBar) < 0)
            Wizard.selectedBar = hits[0];
        refocusTimer.restart();
    }

    // Rows only get their new heights on the next layout pass, so scroll
    // to the selection a moment later (callLater still sees the old layout).
    Timer {
        id: refocusTimer
        interval: 30
        onTriggered: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    // Move the selection through the matching bars only.
    function move(delta: int): void {
        if (!hits.length) return;
        const i = hits.indexOf(Wizard.selectedBar);
        const j = i < 0 ? 0 : Math.max(0, Math.min(hits.length - 1, i + delta));
        Wizard.selectedBar = hits[j];
    }

    // Keys bubble up here from the search field; ←/→ and Enter continue
    // on to shell.qml.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) { move(-1); event.accepted = true; }
        else if (event.key === Qt.Key_Down) { move(1); event.accepted = true; }
        else if (event.key === Qt.Key_PageUp) { move(-8); event.accepted = true; }
        else if (event.key === Qt.Key_PageDown) { move(8); event.accepted = true; }
    }

    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // -- List ------------------------------------------------------
        Panel {
            id: listPanel
            width: Math.round(parent.width * 0.25)
            height: parent.height

            Text {
                id: listTitle
                anchors { top: parent.top; left: parent.left; margins: Theme.spacingM }
                text: "BARS  ·  " + (page.needle.length ? page.hits.length + " / " : "") + page.bars.length
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontXs
                font.weight: Font.Bold
                font.letterSpacing: 1
            }

            Rectangle {
                id: searchBox
                anchors {
                    top: listTitle.bottom; topMargin: Theme.spacingS
                    left: parent.left; right: parent.right
                    leftMargin: Theme.spacingS; rightMargin: Theme.spacingS
                }
                height: 32
                radius: Theme.radiusSmall
                color: Theme.panelAlt
                border.width: Theme.borderWidth
                border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Icon {
                    id: searchIcon
                    anchors { left: parent.left; leftMargin: Theme.spacingS + 2; verticalCenter: parent.verticalCenter }
                    text: "\uf002"
                    size: Theme.fontS
                    color: search.activeFocus ? Theme.accent : Theme.textFaint
                }

                Text {
                    anchors { left: search.left; verticalCenter: parent.verticalCenter }
                    visible: search.text.length === 0
                    text: "Bar suchen …"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                }

                TextInput {
                    id: search
                    anchors {
                        left: searchIcon.right; leftMargin: Theme.spacingS
                        right: clearBtn.left; rightMargin: Theme.spacingXs
                        verticalCenter: parent.verticalCenter
                    }
                    focus: true
                    clip: true
                    selectByMouse: true
                    color: Theme.text
                    selectionColor: Theme.select
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    onTextChanged: page.query = text
                    // Esc clears a non-empty search first, the next Esc
                    // closes the menu (shell.qml).
                    Keys.onEscapePressed: event => {
                        if (text.length) { text = ""; event.accepted = true; }
                        else event.accepted = false;
                    }
                }

                Icon {
                    id: clearBtn
                    anchors { right: parent.right; rightMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                    width: search.text.length ? 16 : 0
                    visible: search.text.length > 0
                    text: "\uf00d"
                    size: Theme.fontS
                    color: clearMouse.containsMouse ? Theme.text : Theme.textFaint
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { search.text = ""; search.forceActiveFocus(); }
                    }
                }

                MouseArea {
                    anchors { fill: parent; rightMargin: clearBtn.width + Theme.spacingS }
                    cursorShape: Qt.IBeamCursor
                    acceptedButtons: Qt.NoButton
                }
            }

            Text {
                anchors { top: searchBox.bottom; topMargin: Theme.spacingL; horizontalCenter: parent.horizontalCenter }
                visible: page.hits.length === 0
                text: "Keine Treffer"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontM
            }

            ListView {
                id: list
                anchors {
                    top: searchBox.bottom; topMargin: Theme.spacingS
                    left: parent.left; right: parent.right; bottom: parent.bottom
                    leftMargin: Theme.spacingS; rightMargin: Theme.spacingS; bottomMargin: Theme.spacingS
                }
                clip: true
                model: page.bars
                // Gaps live inside the rows (margins 1) so hidden rows
                // (height 0) don't leave spacing behind.
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                // ↑/↓ are handled by the page (only through matching bars).
                keyNavigationEnabled: false
                highlightMoveDuration: Theme.animFast
                highlightFollowsCurrentItem: true
                currentIndex: Math.max(0, page.bars.indexOf(Wizard.selectedBar))

                // Keep every row alive: destroying a delegate while its
                // BarTheme's JSON is still loading segfaults Quickshell 0.3.1
                // (JsonAdapter -> QJSEngine::create on a dead object).
                cacheBuffer: 100000

                highlight: Item {
                    width: list.width
                    visible: page.hits.length > 0
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        radius: Theme.radiusSmall
                        color: Theme.select
                    }
                }

                delegate: Item {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property bool active: modelData === BarsModel.activeBar
                    readonly property BarTheme theme: BarTheme { barName: row.modelData }
                    readonly property bool shown: page.matches(modelData)

                    width: ListView.view.width
                    height: shown ? Theme.listRowHeight : 0
                    visible: shown

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        radius: Theme.radiusSmall
                        color: rowMouse.containsMouse && !row.current ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    // Mini swatch in the bar's own colors
                    Rectangle {
                        id: swatch
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26; height: 18; radius: 5
                        color: row.theme.surface
                        border.width: 1
                        border.color: row.current ? Qt.rgba(1, 1, 1, 0.6) : Theme.border
                        Rectangle {
                            anchors.centerIn: parent
                            width: 12; height: 4; radius: 2
                            color: row.theme.accent
                        }
                    }

                    Column {
                        anchors.left: swatch.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: badge.left
                        anchors.rightMargin: Theme.spacingXs
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData
                            color: row.current ? Theme.selectText : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                            font.weight: row.current ? Font.DemiBold : Font.Normal
                        }
                        Text {
                            width: parent.width
                            visible: text.length > 0
                            elide: Text.ElideRight
                            text: BarInfo.titleOf(row.modelData)
                            color: row.current ? Qt.rgba(1, 1, 1, 0.8) : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXs
                        }
                    }

                    Rectangle {
                        id: badge
                        visible: row.active
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        width: visible ? badgeText.implicitWidth + 10 : 0
                        height: 16
                        radius: 8
                        color: row.current ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: "aktiv"
                            color: row.current ? "#ffffff" : Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wizard.selectedBar = row.modelData
                        onDoubleClicked: Wizard.apply()
                    }
                }

                // Thin scroll indicator
                Rectangle {
                    visible: list.contentHeight > list.height
                    anchors.right: parent.right
                    anchors.rightMargin: -Theme.spacingXs
                    y: list.visibleArea.yPosition * list.height
                    width: 3
                    height: list.visibleArea.heightRatio * list.height
                    radius: 1.5
                    color: Theme.textFaint
                    opacity: list.moving ? 0.9 : 0.4
                    Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                }
            }
        }

        // -- Preview ---------------------------------------------------
        Panel {
            id: previewPanel
            width: parent.width - listPanel.width - parent.spacing
            height: parent.height

            Item {
                id: previewBody
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                Row {
                    id: heading
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: Theme.spacingM

                    Text {
                        id: nameText
                        text: page.shown
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontXl
                        font.weight: Font.Bold
                    }
                    Text {
                        anchors.baseline: nameText.baseline
                        width: parent.width - nameText.width - parent.spacing
                        elide: Text.ElideRight
                        text: BarInfo.titleOf(page.shown)
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontM
                    }
                }

                Text {
                    id: pathText
                    anchors { top: heading.bottom; topMargin: 2; left: parent.left }
                    text: BarsModel.barsPath + "/" + page.shown
                    color: Theme.textFaint
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontXs
                }

                // 16:9 box that fits whatever height is left after text.
                Item {
                    id: mockBox
                    anchors { top: pathText.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right; bottom: descText.top; bottomMargin: Theme.spacingM }

                    BarMockup {
                        id: mock
                        barName: page.shown
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: Math.min(parent.height, parent.width * 9 / 16)
                        width: height * 16 / 9

                        // Fade when the selection changes.
                        opacity: 1
                        onBarNameChanged: fade.restart()
                        SequentialAnimation {
                            id: fade
                            NumberAnimation { target: mock; property: "opacity"; to: 0.35; duration: 60 }
                            NumberAnimation { target: mock; property: "opacity"; to: 1; duration: Theme.animPage; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    id: descText
                    anchors { left: parent.left; right: parent.right; bottom: chips.top; bottomMargin: Theme.spacingM }
                    text: BarInfo.descriptionOf(page.shown)
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.2
                }

                Flow {
                    id: chips
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: Theme.spacingS
                    readonly property BarTheme theme: mock.theme

                    InfoChip {
                        visible: page.shown === BarsModel.activeBar
                        icon: ""; tint: Theme.success
                        text: "Aktuell aktiv"
                    }
                    InfoChip { icon: ""; text: Math.round(chips.theme.barOpacity * 100) + " % Deckkraft" }
                    InfoChip { icon: ""; text: "Radius " + chips.theme.radius + " px" }
                    InfoChip {
                        icon: ""
                        text: {
                            const l = LauncherStore.effective(page.shown);
                            return l === page.shown ? "Eigener Launcher"
                                : l === "appsearch" ? "App-Suche vom Menü"
                                : "Launcher von " + l;
                        }
                    }
                    InfoChip {
                        icon: ""
                        text: chips.theme.keybinds.length + " Keybind" + (chips.theme.keybinds.length === 1 ? "" : "s")
                    }
                }
            }
        }
    }
}
