import QtQuick
import "../../../.."

// Krabbe: breiter, flacher Koerper, 6 Laufbeine + 2 Scheren vorne. Gleiches
// Bewegungsprinzip wie Spider.qml (rotiert in Laufrichtung, Beine schwingen
// nur bei Bewegung) -- bewusst kein seitwaerts-Gang-Sonderfall, um die
// Animationslogik zwischen den Figuren identisch zu halten.
Item {
    id: root

    property real size: 48
    property real heading: 0
    property bool moving: false

    implicitWidth: size
    implicitHeight: size
    rotation: heading * 180 / Math.PI

    property real _legPhase: 0
    NumberAnimation on _legPhase {
        running: root.moving
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 420
    }

    Repeater {
        model: 6
        delegate: Rectangle {
            id: leg
            required property int index
            readonly property bool leftSide: index < 3
            readonly property int pairIndex: index % 3
            readonly property real baseAngle: (leftSide ? -1 : 1) * (55 + pairIndex * 25)
            readonly property real swing: root.moving ? Math.sin(root._legPhase + pairIndex * Math.PI / 1.5 + (leftSide ? Math.PI : 0)) * 22 : 0

            width: root.size * 0.36
            height: Math.max(2, root.size * 0.05)
            radius: height / 2
            color: Colors.text
            antialiasing: true

            x: root.size / 2
            y: root.size / 2 - height / 2
            transformOrigin: Item.Left
            rotation: baseAngle + swing
        }
    }

    // Scheren: fest nach vorne (nach der Rotation = in Laufrichtung).
    Rectangle {
        id: leftClaw
        width: root.size * 0.22
        height: root.size * 0.14
        radius: height / 2
        color: Colors.accentAlt
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
        x: root.size * 0.5 - width - root.size * 0.06
        y: root.size * 0.5 - root.size * 0.32
    }
    Rectangle {
        id: rightClaw
        width: root.size * 0.22
        height: root.size * 0.14
        radius: height / 2
        color: Colors.accentAlt
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
        x: root.size * 0.5 + root.size * 0.06
        y: root.size * 0.5 - root.size * 0.32
    }

    Rectangle {
        id: body
        anchors.centerIn: parent
        width: root.size * 0.62
        height: root.size * 0.4
        radius: height / 2
        color: Colors.accent
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
    }
}
