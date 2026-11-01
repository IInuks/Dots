import QtQuick
import QtQuick.Shapes
import Quickshell
import "../core"

// Himmel und Hoelle: das gefaltete Papier-Orakel als Ausschalt-Menue.
// Geschlossen liegen vier farbige Dreiecke ueber der Mitte, beim Oeffnen
// klappen sie nacheinander nach aussen und zeigen ihre Aktion. Erster
// Klick waehlt (Mitte fragt nach), zweiter Klick fuehrt aus.
Menu {
    id: m
    menuId: "power"
    width: 340
    height: 340
    openDuration: 900
    closeDuration: 420

    readonly property real s: 150     // Kantenlaenge der Mitte
    property int armed: -1
    onShownChanged: armed = -1

    readonly property var actions: [
        { label: "Ruhe", icon: "", hint: "in den Ruhezustand", cmd: ["loginctl", "suspend"] },
        { label: "Neustart", icon: "", hint: "neu starten", cmd: ["loginctl", "reboot"] },
        { label: "Aus", icon: "", hint: "ausschalten", cmd: ["loginctl", "poweroff"] },
        { label: "Abmelden", icon: "", hint: "mango beenden", cmd: ["mmsg", "dispatch", "quit"] }
    ]

    function pick(i) {
        if (armed === i) {
            Falt.close();
            Quickshell.execDetached(actions[i].cmd);
        } else {
            armed = i;
        }
    }

    Item {
        id: board
        width: m.s
        height: m.s
        anchors.centerIn: parent
        rotation: (1 - m.progress) * -45
        scale: 0.55 + 0.45 * m.progress
        opacity: Math.min(1, m.progress * 4)

        // Mitte
        Rectangle {
            anchors.fill: parent
            color: Paper.paper
            border.width: 1
            border.color: Paper.deep
            // Faltlinien
            Rectangle { anchors.centerIn: parent; width: parent.width * 1.41; height: 1; rotation: 45; color: Paper.deep }
            Rectangle { anchors.centerIn: parent; width: parent.width * 1.41; height: 1; rotation: -45; color: Paper.deep }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: m.armed >= 0 ? "Sicher?" : "Wähle"
                    font.family: Paper.serif
                    font.pixelSize: 17
                    font.bold: true
                    color: m.armed >= 0 ? Paper.accent : Paper.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: m.armed >= 0 ? "nochmal tippen zum\n" + m.actions[m.armed].hint : "ein Feld"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Paper.serif
                    font.italic: true
                    font.pixelSize: 11
                    color: Paper.soft
                }
            }
        }

        // vier Klappen; jede liegt in einem um 90 Grad gedrehten "Arm"
        Repeater {
            model: 4
            delegate: Item {
                id: arm
                required property int index
                readonly property var act: m.actions[index]
                readonly property bool hot: area.containsMouse
                readonly property bool armed: m.armed === index
                // gestaffelt aufklappen
                readonly property real local: Math.max(0, Math.min(1, m.progress * 1.6 - index * 0.2))
                readonly property real angle: 180 * (1 - local) + (hot && local > 0.99 ? -14 : 0)

                anchors.fill: parent
                rotation: index * 90

                Item {
                    id: flap
                    x: 0
                    y: -m.s / 2
                    width: m.s
                    height: m.s / 2

                    transform: Rotation {
                        origin.x: flap.width / 2
                        origin.y: flap.height
                        axis { x: 1; y: 0; z: 0 }
                        angle: arm.angle
                        Behavior on angle {
                            enabled: m.progress >= 0.999
                            NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                        }
                    }

                    readonly property bool back: arm.angle > 90

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: 1
                            strokeColor: flap.back ? Qt.darker(fillColor, 1.2) : Paper.deep
                            fillColor: flap.back ? (arm.index % 2 ? Paper.second : Paper.accent) : (arm.armed ? Paper.accent : Paper.paper)
                            startX: 0; startY: flap.height
                            PathLine { x: flap.width; y: flap.height }
                            PathLine { x: flap.width / 2; y: 0 }
                            PathLine { x: 0; y: flap.height }
                        }
                    }

                    // Beschriftung (Vorderseite), immer aufrecht
                    Column {
                        visible: !flap.back
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: flap.height * 0.38
                        rotation: -arm.index * 90
                        spacing: 0
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: arm.act.icon
                            font.family: Paper.mono
                            font.pixelSize: 17
                            color: arm.armed ? Paper.accentInk : Paper.ink
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: arm.act.label
                            font.family: Paper.serif
                            font.pixelSize: 11
                            color: arm.armed ? Paper.accentInk : Paper.soft
                        }
                    }
                }

                MouseArea {
                    id: area
                    x: m.s * 0.2
                    y: -m.s / 2 + 8
                    width: m.s * 0.6
                    height: m.s / 2 - 8
                    hoverEnabled: true
                    enabled: m.shown && arm.local > 0.99
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m.pick(arm.index)
                }
            }
        }
    }
}
