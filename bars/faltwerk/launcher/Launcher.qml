import QtQuick
import "../core"
import "../fold"

// Der Launcher ist ein zweimal gefalteter Bogen: geschlossen sieht man nur
// ein Viertel mit Kranich-Stempel, beim Oeffnen klappt erst die untere,
// dann die rechte Haelfte auf. Darauf: Suchzeile und die Apps als
// Origami-Kaertchen. Enter faltet die gewaehlte App zum Papierflieger.
//
// "> befehl" fuehrt einen Shell-Befehl aus.
FocusScope {
    id: l
    required property string screenName
    property real areaWidth: 1920
    property real areaHeight: 1080

    readonly property bool shown: Falt.isOpen("launcher", screenName)
    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: l.shown ? 820 : 480
            easing.type: l.shown ? Easing.OutQuad : Easing.InQuad
        }
    }

    anchors.fill: parent
    visible: progress > 0.001
    focus: shown

    readonly property real sheetW: Math.min(912, areaWidth - 80)
    readonly property real sheetH: Math.min(600, areaHeight - Paper.barZone - 80)
    readonly property int cols: Math.max(3, Math.floor((sheetW - 64) / 128))

    property string query: ""
    readonly property bool commandMode: query.startsWith(">")
    readonly property var results: commandMode ? [] : Apps.search(query)

    onShownChanged: {
        if (shown) {
            input.text = "";
            grid.currentIndex = 0;
            grid.positionViewAtBeginning();
            focusTimer.restart();
        }
    }
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: input.forceActiveFocus()
    }

    function launch(i) {
        if (commandMode) {
            const cmd = query.slice(1).trim();
            if (cmd !== "") {
                const p = input.mapToItem(l, input.width / 2, input.height / 2);
                Falt.launched(screenName, p.x, p.y, Paper.accent);
                Apps.run(cmd);
                Falt.close();
            }
            return;
        }
        const e = results[i];
        if (!e)
            return;
        const it = grid.itemAtIndex(i);
        const p = it ? it.mapToItem(l, it.width / 2, 54) : Qt.point(areaWidth / 2, areaHeight / 2);
        Falt.launched(screenName, p.x, p.y, Paper.tileColor(e.name));
        Apps.launch(e);
        Falt.close();
    }

    readonly property real pA: Math.max(0, Math.min(1, progress * 2))
    readonly property real pB: Math.max(0, Math.min(1, progress * 2 - 1))

    Item {
        id: stage
        width: l.sheetW
        height: l.sheetH
        x: (l.areaWidth - width) / 2 + (width - width * inner.extent) / 2
        y: Paper.barZone + (l.areaHeight - Paper.barZone - height) / 2 - 10 + (height - height * outer.extent) / 2
        scale: 0.9 + 0.1 * Math.min(1, l.progress * 3)
        opacity: Math.min(1, l.progress * 6)

        // Schatten unter dem sichtbaren Teil
        Rectangle {
            x: 4
            y: 7
            width: l.sheetW * inner.extent
            height: l.sheetH * outer.extent
            radius: 6
            color: "#000000"
            opacity: Paper.dark ? 0.5 : 0.22
        }

        Flap {
            id: outer
            anchors.fill: parent
            horizontal: false
            progress: l.pA
            backFraction: inner.extent
            radius: 6

            Flap {
                id: inner
                anchors.fill: parent
                horizontal: true
                progress: l.pB
                radius: 6

                Sheet {
                    anchors.fill: parent
                    radius: 6
                    lift: 0

                    // Knicklinien der Faltung bleiben leicht sichtbar
                    Rectangle { x: parent.width / 2; width: 1; height: parent.height; color: "#000000"; opacity: 0.05 }
                    Rectangle { y: parent.height / 2; height: 1; width: parent.width; color: "#000000"; opacity: 0.05 }

                    // ---- Kopf ----
                    Crane {
                        x: 30
                        y: 26
                        width: 40
                        height: 40
                        tint: Paper.ink
                        wing: Paper.accent
                    }
                    Item {
                        id: field
                        x: 84
                        y: 26
                        width: parent.width - 84 - 150
                        height: 44

                        TextInput {
                            id: input
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Paper.serif
                            font.pixelSize: 24
                            font.italic: l.commandMode
                            color: Paper.ink
                            selectionColor: Paper.accent
                            selectedTextColor: Paper.accentInk
                            focus: true
                            clip: true
                            onTextChanged: {
                                l.query = text;
                                grid.currentIndex = 0;
                            }
                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Down) {
                                    grid.moveCurrentIndexDown();
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Up) {
                                    grid.moveCurrentIndexUp();
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Right && (cursorPosition === text.length)) {
                                    grid.moveCurrentIndexRight();
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Left && (cursorPosition === 0)) {
                                    grid.moveCurrentIndexLeft();
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Tab) {
                                    grid.currentIndex = (grid.currentIndex + 1) % Math.max(1, grid.count);
                                    e.accepted = true;
                                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    l.launch(grid.currentIndex);
                                    e.accepted = true;
                                }
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: "Was soll gefaltet werden?"
                            font.family: Paper.serif
                            font.pixelSize: 24
                            font.italic: true
                            color: Paper.soft
                            opacity: 0.7
                        }
                        // Bleistiftlinie
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2
                            radius: 1
                            color: Paper.ink
                            opacity: 0.25
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            height: 2
                            radius: 1
                            width: Math.min(parent.width, input.contentWidth + 8)
                            color: Paper.accent
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 32
                        y: 36
                        text: l.commandMode ? "Befehl" : l.results.length + (l.results.length === 1 ? " Bogen" : " Bögen")
                        font.family: Paper.serif
                        font.italic: true
                        font.pixelSize: 14
                        color: Paper.soft
                    }

                    Text {
                        x: 34
                        y: 90
                        text: l.commandMode ? "" : (l.query === "" ? "Oft gefaltet" : "Treffer")
                        font.family: Paper.serif
                        font.pixelSize: 12
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 2
                        color: Paper.accent
                    }

                    // ---- Raster ----
                    GridView {
                        id: grid
                        x: (parent.width - l.cols * 128) / 2
                        y: 110
                        width: l.cols * 128
                        height: parent.height - 110 - 46
                        cellWidth: 128
                        cellHeight: 146
                        clip: true
                        model: l.results
                        keyNavigationEnabled: false
                        highlightFollowsCurrentItem: false
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: 600
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                        delegate: AppTile {
                            selected: GridView.isCurrentItem
                            onHovered: grid.currentIndex = index
                            onActivated: l.launch(index)
                        }
                    }

                    // leer / Befehl
                    Column {
                        anchors.centerIn: grid
                        visible: l.commandMode || l.results.length === 0
                        spacing: 8
                        Crane {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64
                            height: 64
                            tint: Paper.soft
                            wing: l.commandMode ? Paper.accent : Paper.deep
                            opacity: 0.8
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: l.commandMode ? (l.query.slice(1).trim() === "" ? "Befehl eingeben …" : "↵  " + l.query.slice(1).trim()) : "Kein Bogen passt."
                            font.family: l.commandMode ? Paper.mono : Paper.serif
                            font.italic: !l.commandMode
                            font.pixelSize: 16
                            color: Paper.ink
                        }
                    }

                    // ---- Fuss ----
                    Rectangle {
                        y: parent.height - 40
                        x: 24
                        width: parent.width - 48
                        height: 1
                        color: Paper.deep
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - 30
                        text: "↵ falten   ·   ← ↑ → ↓ wählen   ·   > Befehl   ·   Esc zurück"
                        font.family: Paper.serif
                        font.italic: true
                        font.pixelSize: 12
                        color: Paper.soft
                    }
                }
            }
        }

        // Klicks auf dem Bogen nicht als "daneben" werten
        MouseArea {
            z: -1
            anchors.fill: parent
            enabled: l.shown
        }
    }
}
