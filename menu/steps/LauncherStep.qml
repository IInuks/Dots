import QtQuick
import ".."
import "../components"

// "Launcher" tab: mix launchers across bars. Same layout as "Bars": left
// 25 % search + list of every launcher (the menu's app search plus each
// bar's own, see LauncherStore), right 75 % name, preview, description and
// the bars that use it. Enter / double-click / "Anwenden" assigns the
// selected launcher to the active bar; a click on a bar chip assigns it to
// that bar (again = back to the bar's default). Assignments stay until
// they're changed -- switching to a bar always brings its launcher along.
FocusScope {
    id: page

    readonly property var launchers: LauncherStore.ids
    readonly property string shown: Wizard.selectedLauncher
    readonly property string inUse: LauncherStore.effective(BarsModel.activeBar)

    Component.onCompleted: {
        if (!Wizard.selectedLauncher.length || launchers.indexOf(Wizard.selectedLauncher) < 0)
            Wizard.selectedLauncher = inUse;
    }

    // Search: matches id or title, case-insensitive. Rows that don't match
    // are only hidden (see BarStep: the model stays, BarThemes stay alive).
    property string query: ""
    readonly property string needle: query.trim().toLowerCase()
    function matches(id: string): bool {
        return needle.length === 0
            || LauncherStore.nameOf(id).toLowerCase().includes(needle)
            || LauncherStore.titleOf(id).toLowerCase().includes(needle);
    }
    readonly property var hits: launchers.filter(n => matches(n))

    onHitsChanged: {
        if (hits.length && hits.indexOf(Wizard.selectedLauncher) < 0)
            Wizard.selectedLauncher = hits[0];
        refocusTimer.restart();
    }

    Timer {
        id: refocusTimer
        interval: 30
        onTriggered: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function move(delta: int): void {
        if (!hits.length) return;
        const i = hits.indexOf(Wizard.selectedLauncher);
        const j = i < 0 ? 0 : Math.max(0, Math.min(hits.length - 1, i + delta));
        Wizard.selectedLauncher = hits[j];
    }

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
                text: "LAUNCHER  ·  " + (page.needle.length ? page.hits.length + " / " : "") + page.launchers.length
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
                    text: ""
                    size: Theme.fontS
                    color: search.activeFocus ? Theme.accent : Theme.textFaint
                }

                Text {
                    anchors { left: search.left; verticalCenter: parent.verticalCenter }
                    visible: search.text.length === 0
                    text: "Launcher suchen …"
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
                    text: ""
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
                text: page.launchers.length ? "Keine Treffer" : "Lade …"
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
                model: page.launchers
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                highlightMoveDuration: Theme.animFast
                highlightFollowsCurrentItem: true
                currentIndex: Math.max(0, page.launchers.indexOf(Wizard.selectedLauncher))

                // Keep every row alive (BarTheme per row, see BarStep).
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
                    readonly property bool active: modelData === page.inUse
                    readonly property int users: LauncherStore.barsUsing(modelData).length
                    // The app search wears the active bar's colors.
                    readonly property BarTheme theme: BarTheme {
                        barName: row.modelData === "appsearch" ? BarsModel.activeBar : row.modelData
                    }
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

                    // Mini launcher card in the source bar's colors
                    Rectangle {
                        id: swatch
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22; radius: 6
                        color: row.theme.surface
                        border.width: 1
                        border.color: row.current ? Qt.rgba(1, 1, 1, 0.6) : Theme.border
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Rectangle { width: 12; height: 3; radius: 1.5; color: row.theme.accent }
                            Rectangle { width: 12; height: 2; radius: 1; color: Qt.alpha(row.theme.foreground, 0.5) }
                            Rectangle { width: 9; height: 2; radius: 1; color: Qt.alpha(row.theme.foreground, 0.3) }
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
                            text: LauncherStore.nameOf(row.modelData)
                            color: row.current ? Theme.selectText : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                            font.weight: row.current ? Font.DemiBold : Font.Normal
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.users > 0
                                ? LauncherStore.titleOf(row.modelData) + "  ·  " + row.users + (row.users === 1 ? " Bar" : " Bars")
                                : LauncherStore.titleOf(row.modelData)
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
                        onClicked: Wizard.selectedLauncher = row.modelData
                        onDoubleClicked: Wizard.apply()
                    }
                }

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

        // -- Preview + assignment --------------------------------------
        Panel {
            id: previewPanel
            width: parent.width - listPanel.width - parent.spacing
            height: parent.height

            Item {
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                Row {
                    id: heading
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: Theme.spacingM

                    Text {
                        id: nameText
                        text: LauncherStore.nameOf(page.shown)
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontXl
                        font.weight: Font.Bold
                    }
                    Text {
                        anchors.baseline: nameText.baseline
                        width: parent.width - nameText.width - parent.spacing
                        elide: Text.ElideRight
                        text: LauncherStore.titleOf(page.shown)
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontM
                    }
                }

                Text {
                    id: pathText
                    anchors { top: heading.bottom; topMargin: 2; left: parent.left; right: parent.right }
                    elide: Text.ElideMiddle
                    text: page.shown === "appsearch"
                        ? "menu/AppSearch.qml  ·  Teil dieses Menüs"
                        : BarsModel.barsPath + "/" + page.shown + "  ·  ohne Bar über menu/launchers/hosts/" + page.shown + ".qml"
                    color: Theme.textFaint
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontXs
                }

                Item {
                    id: mockBox
                    anchors { top: pathText.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right; bottom: descText.top; bottomMargin: Theme.spacingM }

                    LauncherMockup {
                        id: mock
                        launcherId: page.shown
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: Math.min(parent.height, parent.width * 9 / 16)
                        width: height * 16 / 9

                        opacity: 1
                        onLauncherIdChanged: fade.restart()
                        SequentialAnimation {
                            id: fade
                            NumberAnimation { target: mock; property: "opacity"; to: 0.35; duration: 60 }
                            NumberAnimation { target: mock; property: "opacity"; to: 1; duration: Theme.animPage; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    id: descText
                    anchors { left: parent.left; right: parent.right; bottom: usersTitle.top; bottomMargin: Theme.spacingM }
                    text: LauncherStore.descriptionOf(page.shown)
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    lineHeight: 1.2
                }

                Text {
                    id: usersTitle
                    anchors { left: parent.left; right: parent.right; bottom: chips.top; bottomMargin: Theme.spacingS }
                    elide: Text.ElideRight
                    text: "VERWENDET VON  ·  Klick auf eine Bar weist ihr diesen Launcher zu, nochmal klicken = zurück zum Standard"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontXs
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                }

                // One chip per bar: filled = uses this launcher (assigned,
                // or "Standard" when it's that bar's own default).
                Flow {
                    id: chips
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: 6

                    Repeater {
                        model: BarsModel.barNames
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            readonly property bool uses: LauncherStore.effective(modelData) === page.shown
                            readonly property bool assigned: uses && LauncherStore.isAssigned(modelData)
                            readonly property bool isDefault: uses && !assigned
                            readonly property bool activeBar: modelData === BarsModel.activeBar
                            readonly property bool clickable: !Wizard.locked && !isDefault
                            readonly property bool pending: LauncherStore.running && LauncherStore.targetBar === modelData

                            implicitWidth: chipRow.implicitWidth + 16
                            implicitHeight: 24
                            radius: height / 2
                            color: uses ? Qt.alpha(Theme.accent, chipMouse.containsMouse && clickable ? 0.3 : 0.18)
                                 : (chipMouse.containsMouse && clickable ? Theme.panelAlt : "transparent")
                            border.width: Theme.borderWidth
                            border.color: uses ? Qt.alpha(Theme.accent, 0.7) : (chipMouse.containsMouse && clickable ? Theme.textDim : Theme.border)
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5

                                Spinner {
                                    visible: chip.pending
                                    running: visible
                                    size: Theme.fontXs
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Icon {
                                    visible: chip.uses && !chip.pending
                                    text: ""
                                    size: Theme.fontXs
                                    color: Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: chip.modelData
                                    color: chip.uses ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontS
                                    font.weight: chip.activeBar ? Font.Bold : Font.Normal
                                    font.underline: chip.activeBar
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    visible: chip.isDefault
                                    text: "Standard"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: chip.clickable
                                cursorShape: chip.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: LauncherStore.assign(chip.modelData, chip.assigned ? "default" : page.shown)
                            }
                        }
                    }
                }
            }
        }
    }
}
