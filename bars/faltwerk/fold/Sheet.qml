import QtQuick
import "../core"

// Ein Blatt Papier: Papierfarbe, Faserkorn, feiner Rand und ein harter,
// leicht versetzter Schatten (wie Papier, das knapp ueber dem Tisch liegt).
Rectangle {
    id: root
    property color tint: Paper.paper
    property real lift: 1          // 0 = flach, 1 = normal, 2 = angehoben
    property bool grainVisible: true

    color: tint
    radius: 5
    border.width: 1
    border.color: Qt.darker(tint, Paper.dark ? 1.35 : 1.08)

    Rectangle {
        z: -1
        x: 1 + root.lift
        y: 2 + root.lift * 1.6
        width: root.width
        height: root.height
        radius: root.radius
        color: "#000000"
        opacity: root.lift <= 0 ? 0 : (Paper.dark ? 0.45 : 0.16)
    }
    Rectangle {
        z: -1
        x: 0
        y: 1
        width: root.width
        height: root.height
        radius: root.radius
        color: "#000000"
        opacity: root.lift <= 0 ? 0 : 0.10
    }

}
