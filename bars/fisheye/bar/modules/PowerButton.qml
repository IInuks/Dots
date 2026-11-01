import QtQuick
import "../.."

// Power glyph -- composited from plain shapes (a ring with a notch cut
// into it, plus the notch's line), same "no font" rule as everything
// else. Only emits `clicked`; Bar.qml owns the PopupShell/PowerMenu that
// actually runs anything, so a stray click here can never by itself
// shut down the session -- the menu's own confirm step does that.
Item {
    id: root

    signal clicked

    implicitWidth: 16
    implicitHeight: 16

    readonly property color ink: hoverArea.containsMouse ? Theme.critical : Theme.surfaceInk

    Rectangle {
        anchors.centerIn: parent
        width: 13
        height: 13
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.ink
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durFast
            }
        }
    }

    // Cuts the notch at the top of the ring so the line reads as sticking
    // out of it, rather than drawing a full unbroken circle.
    Rectangle {
        width: 5
        height: 4
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 8
        color: Theme.surface
    }

    Rectangle {
        width: 2
        height: 7
        radius: 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 9
        color: root.ink
        Behavior on color {
            ColorAnimation {
                duration: Theme.durFast
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
