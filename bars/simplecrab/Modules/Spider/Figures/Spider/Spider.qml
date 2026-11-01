import QtQuick
import "../../../.."

// Einfache, komplett QML-gezeichnete Spinne: runder Koerper + 8 Beine als
// rotierte Balken. Dreht sich als Ganzes in Laufrichtung (heading), Beine
// schwingen nur, waehrend "moving" true ist -- steht sie still, frieren
// sie in Ruheposition ein statt weiterzuzappeln.
Item {
    id: root

    property real size: 48
    property real heading: 0 // radians, 0 = nach rechts
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
        duration: 500
    }

    // 8 Beine, 4 pro Seite. pairIndex verteilt sie von vorne nach hinten,
    // die Sinus-Phasenverschiebung pro Bein ergibt den laufenden
    // Spinnengang statt eines starren Gleichtakts.
    Repeater {
        model: 8
        delegate: Rectangle {
            id: leg
            required property int index
            readonly property bool leftSide: index < 4
            readonly property int pairIndex: index % 4
            readonly property real baseAngle: (leftSide ? -1 : 1) * (35 + pairIndex * 22)
            readonly property real swing: root.moving ? Math.sin(root._legPhase + pairIndex * Math.PI / 2 + (leftSide ? Math.PI : 0)) * 18 : 0

            width: root.size * 0.42
            height: Math.max(2, root.size * 0.045)
            radius: height / 2
            color: Colors.text
            antialiasing: true

            x: root.size / 2
            y: root.size / 2 - height / 2
            transformOrigin: Item.Left
            rotation: baseAngle + swing
        }
    }

    Rectangle {
        id: body
        anchors.centerIn: parent
        width: root.size * 0.5
        height: root.size * 0.4
        radius: height / 2
        color: Colors.accent
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
    }

    // Kopf-/Vorderteil, leicht versetzt Richtung "vorne" (oben vor der
    // Rotation), macht die Blickrichtung auch ohne Augen erkennbar.
    Rectangle {
        width: root.size * 0.3
        height: root.size * 0.26
        radius: height / 2
        color: Colors.accent
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
        anchors.horizontalCenter: body.horizontalCenter
        anchors.bottom: body.top
        anchors.bottomMargin: -height * 0.3
    }
}
