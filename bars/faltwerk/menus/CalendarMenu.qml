import QtQuick
import "../core"
import "../fold"

// Abreisskalender: faltet sich als Leporello (3 Streifen) nach unten auf.
// Oben das grosse Tagesblatt mit Perforation, darunter der Monat mit
// Kalenderwochen. Monatswechsel (Pfeile/Mausrad) blaettert die Seite um.
Menu {
    id: m
    menuId: "calendar"
    width: 330
    height: 432

    readonly property var de: Qt.locale("de_DE")
    property date now: new Date()
    onShownChanged: if (shown) {
        now = new Date();
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
    }

    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property int shownYear: viewYear
    property int shownMonth: viewMonth
    property real pageTurn: 0
    property int dir: 1

    function step(d) {
        dir = d;
        let mth = viewMonth + d, yr = viewYear;
        if (mth < 0) { mth = 11; yr--; }
        if (mth > 11) { mth = 0; yr++; }
        viewMonth = mth;
        viewYear = yr;
        turnAnim.restart();
    }
    SequentialAnimation {
        id: turnAnim
        NumberAnimation { target: m; property: "pageTurn"; to: 90 * m.dir; duration: 140; easing.type: Easing.InQuad }
        ScriptAction { script: { m.shownYear = m.viewYear; m.shownMonth = m.viewMonth; } }
        NumberAnimation { target: m; property: "pageTurn"; from: -90 * m.dir; to: 0; duration: 320; easing.type: Easing.OutBack }
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    // 6 Wochen x 7 Tage ab dem Montag vor dem Monatsersten
    readonly property var cells: {
        const first = new Date(shownYear, shownMonth, 1);
        const off = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(shownYear, shownMonth, 1 - off + i);
            out.push(d);
        }
        return out;
    }

    Fold {
        width: m.width + 6
        height: m.height + 6
        segments: 3
        progress: m.progress

        Sheet {
            anchors.fill: parent
            anchors.rightMargin: 6
            anchors.bottomMargin: 6

            // ---- Tagesblatt ----
            Item {
                id: leaf
                x: 0
                y: 0
                width: parent.width
                height: 128

                Text {
                    id: dayNum
                    x: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: m.now.getDate()
                    font.family: Paper.serif
                    font.pixelSize: 72
                    font.bold: true
                    color: Paper.accent
                }
                Column {
                    anchors.left: dayNum.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: m.now.toLocaleString(m.de, "dddd")
                        font.family: Paper.serif
                        font.pixelSize: 20
                        color: Paper.ink
                    }
                    Text {
                        text: m.now.toLocaleString(m.de, "MMMM yyyy")
                        font.family: Paper.serif
                        font.italic: true
                        font.pixelSize: 14
                        color: Paper.soft
                    }
                    Text {
                        text: "KW " + m.isoWeek(m.now) + "  ·  Tag " + Math.floor((m.now - new Date(m.now.getFullYear(), 0, 0)) / 86400000)
                        font.family: Paper.mono
                        font.pixelSize: 11
                        color: Paper.soft
                    }
                }
            }

            // Perforation
            Row {
                x: 10
                y: leaf.height
                spacing: 6
                Repeater {
                    model: Math.floor((m.width - 20) / 10)
                    delegate: Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: Paper.deep
                        border.width: 1
                        border.color: Qt.darker(Paper.deep, 1.1)
                    }
                }
            }

            // ---- Monat ----
            Item {
                id: monthHead
                y: leaf.height + 14
                width: parent.width
                height: 34

                Text {
                    anchors.centerIn: parent
                    text: new Date(m.shownYear, m.shownMonth, 1).toLocaleString(m.de, "MMMM yyyy")
                    font.family: Paper.serif
                    font.pixelSize: 15
                    font.bold: true
                    color: Paper.ink
                }
                Repeater {
                    model: [-1, 1]
                    delegate: Rectangle {
                        required property int modelData
                        x: modelData < 0 ? 16 : parent.width - 16 - width
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 24
                        radius: 4
                        color: navArea.containsMouse ? Paper.deep : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData < 0 ? "‹" : "›"
                            font.family: Paper.serif
                            font.pixelSize: 20
                            color: Paper.ink
                        }
                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: m.step(modelData)
                        }
                    }
                }
            }

            Item {
                id: page
                x: 14
                y: monthHead.y + monthHead.height + 4
                width: parent.width - 28
                height: 7 * 32

                transform: Rotation {
                    origin.x: page.width / 2
                    origin.y: 0
                    axis { x: 1; y: 0; z: 0 }
                    angle: m.pageTurn
                }

                readonly property real cw: width / 8

                // Kopfzeile
                Repeater {
                    model: ["KW", "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    delegate: Text {
                        required property int index
                        required property string modelData
                        x: index * page.cw
                        width: page.cw
                        height: 28
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        font.family: Paper.serif
                        font.pixelSize: 11
                        font.italic: index === 0
                        color: index >= 6 ? Paper.accent : Paper.soft
                    }
                }

                // Wochennummern
                Repeater {
                    model: 6
                    delegate: Text {
                        required property int index
                        x: 0
                        y: 30 + index * 32
                        width: page.cw
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: m.isoWeek(m.cells[index * 7])
                        font.family: Paper.mono
                        font.pixelSize: 10
                        color: Paper.soft
                        opacity: 0.7
                    }
                }
                Rectangle {
                    x: page.cw - 1
                    y: 30
                    width: 1
                    height: 6 * 32
                    color: Paper.deep
                }

                Repeater {
                    model: 42
                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property date d: m.cells[index]
                        readonly property bool inMonth: d.getMonth() === m.shownMonth
                        readonly property bool today: d.toDateString() === m.now.toDateString()
                        x: (1 + index % 7) * page.cw
                        y: 30 + Math.floor(index / 7) * 32
                        width: page.cw
                        height: 30

                        // handgezogener Kreis um heute
                        Rectangle {
                            visible: cell.today
                            anchors.centerIn: parent
                            width: 30
                            height: 26
                            radius: 13
                            rotation: -8
                            color: "transparent"
                            border.width: 2
                            border.color: Paper.accent
                        }
                        Rectangle {
                            visible: cell.today
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 1
                            width: 32
                            height: 24
                            radius: 12
                            rotation: 6
                            color: "transparent"
                            border.width: 1
                            border.color: Paper.accent
                            opacity: 0.6
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.d.getDate()
                            font.family: Paper.serif
                            font.pixelSize: 13
                            font.bold: cell.today
                            color: (cell.index % 7) >= 5 ? Paper.accent : Paper.ink
                            opacity: cell.inMonth ? 1 : 0.3
                        }
                    }
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => m.step(e.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }
}
