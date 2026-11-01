import QtQuick
import "../core"
import "../fold"

// Ton: eine Lasche, die nach unten aufklappt (Leporello mit 2 Streifen).
// Der Regler ist eine Papierfahne, die man an einem Falz entlangzieht;
// darunter die Ausgaenge als Karteireiter.
Menu {
    id: m
    menuId: "sound"
    width: 320
    height: 170 + Math.max(1, Sys.sinks.length) * 38

    onShownChanged: if (shown) Sys.refreshSinks()

    Fold {
        width: m.width + 6
        height: m.height + 6
        segments: 2
        progress: m.progress

        Sheet {
            anchors.fill: parent
            anchors.rightMargin: 6
            anchors.bottomMargin: 6

            Text {
                x: 22
                y: 16
                text: "Ton"
                font.family: Paper.serif
                font.pixelSize: 20
                font.bold: true
                color: Paper.ink
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 22
                y: 10
                text: Math.round(Sys.volume * 100)
                font.family: Paper.serif
                font.pixelSize: 34
                font.bold: true
                color: Sys.muted ? Paper.soft : Paper.accent
                Text {
                    anchors.left: parent.right
                    anchors.baseline: parent.baseline
                    text: "%"
                    font.family: Paper.serif
                    font.pixelSize: 14
                    color: Paper.soft
                }
            }

            // ---- Regler ----
            Item {
                id: slider
                x: 22
                y: 66
                width: parent.width - 44 - 44
                height: 40

                readonly property real frac: Math.min(1, Sys.volume)

                // Falz
                Rectangle {
                    y: parent.height / 2 - 1
                    width: parent.width
                    height: 1
                    color: Qt.darker(Paper.paper, Paper.dark ? 1.6 : 1.2)
                }
                Rectangle {
                    y: parent.height / 2
                    width: parent.width
                    height: 1
                    color: Qt.lighter(Paper.paper, 1.1)
                }
                // gefuellter Teil
                Rectangle {
                    y: parent.height / 2 - 3
                    height: 6
                    radius: 3
                    width: slider.width * slider.frac
                    color: Sys.muted ? Paper.soft : Paper.accent
                    Behavior on width {
                        enabled: !drag.pressed
                        NumberAnimation { duration: 200 }
                    }
                }
                // Fahne
                Item {
                    id: tab
                    x: slider.width * slider.frac - width / 2
                    y: 0
                    width: 22
                    height: 40
                    Behavior on x {
                        enabled: !drag.pressed
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                    rotation: drag.pressed ? -8 : 0
                    Behavior on rotation { NumberAnimation { duration: 160 } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: 2
                        height: parent.height
                        color: Paper.ink
                    }
                    Rectangle {
                        x: parent.width / 2 + 1
                        y: 2
                        width: 18
                        height: 14
                        color: Paper.accent
                        Rectangle {
                            anchors.right: parent.right
                            width: 5
                            height: parent.height
                            color: "#000000"
                            opacity: 0.2
                        }
                    }
                }
                MouseArea {
                    id: drag
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.SizeHorCursor
                    function apply(mx) {
                        Sys.setVolume(Math.max(0, Math.min(1, (mx - 6) / slider.width)));
                    }
                    onPressed: e => apply(e.x)
                    onPositionChanged: e => { if (pressed) apply(e.x); }
                    onWheel: e => Sys.setVolume(Sys.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))
                }
            }

            // Stumm-Knopf
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 18
                y: 70
                width: 34
                height: 32
                radius: 4
                color: Sys.muted ? Paper.accent : (muteArea.containsMouse ? Paper.deep : "transparent")
                border.width: 1
                border.color: Paper.deep
                Behavior on color { ColorAnimation { duration: Paper.tQuick } }
                Text {
                    anchors.centerIn: parent
                    text: Sys.muted ? "" : ""
                    font.family: Paper.mono
                    font.pixelSize: 15
                    color: Sys.muted ? Paper.accentInk : Paper.ink
                }
                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sys.toggleMute()
                }
            }

            Text {
                x: 22
                y: 122
                text: "Ausgang"
                font.family: Paper.serif
                font.italic: true
                font.pixelSize: 12
                color: Paper.soft
            }

            // ---- Ausgaenge als Karteireiter ----
            Column {
                x: 16
                y: 142
                width: parent.width - 32
                spacing: 4
                Repeater {
                    model: Sys.sinks
                    delegate: Item {
                        id: sink
                        required property var modelData
                        required property int index
                        readonly property bool current: modelData.name === Sys.sinkName
                        width: parent.width
                        height: 34

                        // gestaffeltes Hereinschieben
                        opacity: m.progress >= 0.999 ? 1 : 0
                        property real slide: m.progress >= 0.999 ? 0 : 30
                        transform: Translate { x: sink.slide }
                        Behavior on opacity { NumberAnimation { duration: 260 + sink.index * 80 } }
                        Behavior on slide { NumberAnimation { duration: 360 + sink.index * 80; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: sink.current ? Paper.deep : (sinkArea.containsMouse ? Qt.rgba(0, 0, 0, 0.05) : "transparent")
                        }
                        Rectangle {
                            visible: sink.current
                            width: 5
                            height: parent.height
                            radius: 2
                            color: Paper.accent
                        }
                        Text {
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24
                            elide: Text.ElideRight
                            text: sink.modelData.description
                            font.family: Paper.serif
                            font.pixelSize: 13
                            font.bold: sink.current
                            color: Paper.ink
                        }
                        MouseArea {
                            id: sinkArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Sys.setSink(sink.modelData.name)
                        }
                    }
                }
            }
        }
    }
}
