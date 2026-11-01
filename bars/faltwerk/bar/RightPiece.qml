import QtQuick
import QtQuick.Shapes
import Quickshell
import "../core"
import "../fold"

// Rechtes Papierstueck: Messwerk, Ton, Faecher (Papier), Zettel, Uhr,
// Himmel-und-Hoelle (Ausschalten). Jede Facette oeffnet ihr Menue.
Item {
    id: root
    signal open(string id, Item item)

    implicitWidth: lay.implicitWidth
    implicitHeight: Paper.barHeight

    readonly property var de: Qt.locale("de_DE")

    Sheet {
        anchors.fill: parent
    }

    component Click: MouseArea {
        property string menu
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open(menu, parent)
    }

    Row {
        id: lay
        height: parent.height

        // ---- Messwerk: drei Papierstreifen fuer CPU / RAM / Temperatur ----
        Facet {
            id: fStats
            crease: false
            hovered: cStats.containsMouse
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Repeater {
                    model: [
                        { v: Sys.cpu, c: Paper.accent },
                        { v: Sys.mem, c: Paper.second },
                        { v: Math.min(1, Sys.temp / 95), c: Paper.ink }
                    ]
                    delegate: Item {
                        required property var modelData
                        width: 5
                        height: 20
                        Rectangle {
                            anchors.fill: parent
                            radius: 1
                            color: Paper.deep
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 1
                            height: Math.max(2, parent.height * modelData.v)
                            color: modelData.c
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
                        }
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Sys.cpu * 100) + "%"
                font.family: Paper.mono
                font.pixelSize: 12
                color: Paper.ink
                width: 30
            }
            Click { id: cStats; menu: "system"; parent: fStats }
        }

        // ---- Ton ----
        Facet {
            id: fSound
            odd: true
            hovered: cSound.containsMouse
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.muted ? "" : (Sys.volume > 0.5 ? "" : "")
                font.family: Paper.mono
                font.pixelSize: 16
                color: Sys.muted ? Paper.soft : Paper.ink
                width: 18
                scale: cSound.pressed ? 0.85 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.muted ? "stumm" : Math.round(Sys.volume * 100) + "%"
                font.family: Sys.muted ? Paper.serif : Paper.mono
                font.italic: Sys.muted
                font.pixelSize: 12
                color: Paper.ink
            }
            MouseArea {
                id: cSound
                parent: fSound
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: e => {
                    if (e.button === Qt.MiddleButton)
                        Sys.toggleMute();
                    else
                        root.open("sound", fSound);
                }
                onWheel: e => Sys.setVolume(Sys.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))
            }
        }

        // ---- Faecher: Papier waehlen ----
        Facet {
            id: fPaper
            hovered: cPaper.containsMouse
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        x: 10
                        y: 2
                        width: 4
                        height: 18
                        radius: 2
                        color: [Paper.accent, Paper.second, Paper.ink, Paper.soft][index]
                        transformOrigin: Item.Bottom
                        rotation: (index - 1.5) * (cPaper.containsMouse ? 26 : 14)
                        Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                    }
                }
                Rectangle {
                    x: 10
                    y: 18
                    width: 4
                    height: 4
                    radius: 2
                    color: Paper.ink
                }
            }
            Click { id: cPaper; menu: "paper"; parent: fPaper }
        }

        // ---- Zettel ----
        Facet {
            id: fNote
            odd: true
            hovered: cNote.containsMouse
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                Rectangle {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    radius: 1
                    color: Paper.dark ? Paper.accent : "#f4d774"
                    rotation: cNote.containsMouse ? -12 : -5
                    Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            required property int index
                            x: 3
                            y: 5 + index * 4
                            width: 11 - index * 2
                            height: 1
                            color: "#000000"
                            opacity: 0.35
                        }
                    }
                }
                Rectangle {
                    visible: Store.note.trim() !== ""
                    x: 9
                    y: 0
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Paper.second
                }
            }
            Click { id: cNote; menu: "note"; parent: fNote }
        }

        // ---- Uhr ----
        Facet {
            id: fClock
            hovered: cClock.containsMouse
            pad: 12
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            Text {
                id: timeText
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                font.family: Paper.serif
                font.pixelSize: 16
                font.bold: true
                color: Paper.ink

                property real turn: 0
                transform: Rotation {
                    origin.x: timeText.width / 2
                    origin.y: timeText.height / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: timeText.turn
                }
                onTextChanged: tick.restart()
                NumberAnimation {
                    id: tick
                    target: timeText; property: "turn"; from: -90; to: 0; duration: 420; easing.type: Easing.OutBack
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: clock.date.toLocaleString(root.de, "ddd d. MMM")
                font.family: Paper.serif
                font.italic: true
                font.pixelSize: 12
                color: Paper.soft
            }
            Click { id: cClock; menu: "calendar"; parent: fClock }
        }

        // ---- Himmel und Hoelle ----
        Facet {
            id: fPower
            odd: true
            hovered: cPower.containsMouse
            pad: 11
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                rotation: cPower.containsMouse ? 45 : 0
                Behavior on rotation { NumberAnimation { duration: 360; easing.type: Easing.OutBack } }
                Repeater {
                    model: 4
                    delegate: Shape {
                        required property int index
                        anchors.fill: parent
                        rotation: index * 90
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: -1
                            fillColor: [Paper.accent, Paper.second, Paper.accent, Paper.second][index]
                            startX: 11; startY: 11
                            PathLine { x: 3; y: 3 }
                            PathLine { x: 19; y: 3 }
                            PathLine { x: 11; y: 11 }
                        }
                    }
                }
            }
            Click { id: cPower; menu: "power"; parent: fPower }
        }
    }
}
