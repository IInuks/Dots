import QtQuick
import "../core"

// Halbe Faltung um 180 Grad (wie ein gefalteter Zettel): eine Haelfte bleibt
// liegen, die andere klappt um die Mittellinie auf. Liegt die Klappe noch
// oben (>90 Grad), sieht man ihre Rueckseite -- schlichtes Papier mit
// Kranich-Stempel. Verschachtelt ergibt das die Kartenfaltung des Launchers.
Item {
    id: root

    property real progress: 1
    property bool horizontal: true     // true: rechte Haelfte klappt um die senkrechte Mittellinie
    property color backColor: Paper.deep
    property real backFraction: 1      // Anteil der Rueckseite quer zur Achse (bei Verschachtelung)
    property real radius: 6
    property bool stamp: true
    default property alias content: holder.data

    readonly property real _p: Math.max(0, Math.min(1, progress))
    readonly property bool flat: _p >= 0.999
    readonly property real angle: (1 - _p) * 180
    // sichtbarer Anteil entlang der Faltrichtung (0.5 .. 1)
    readonly property real extent: angle >= 90 ? 0.5 : 0.5 + 0.5 * Math.cos(angle * Math.PI / 180)

    Item {
        id: holder
        width: root.width
        height: root.height
    }

    ShaderEffectSource {
        visible: !root.flat
        width: root.horizontal ? root.width / 2 : root.width
        height: root.horizontal ? root.height : root.height / 2
        sourceItem: holder
        hideSource: !root.flat
        live: visible
        sourceRect: Qt.rect(0, 0, width, height)
    }

    Item {
        id: flap
        visible: !root.flat
        x: root.horizontal ? root.width / 2 : 0
        y: root.horizontal ? 0 : root.height / 2
        width: root.horizontal ? root.width / 2 : root.width
        height: root.horizontal ? root.height : root.height / 2

        transform: Rotation {
            origin.x: 0
            origin.y: 0
            axis.x: root.horizontal ? 0 : 1
            axis.y: root.horizontal ? 1 : 0
            axis.z: 0
            angle: root.horizontal ? -root.angle : root.angle
        }

        ShaderEffectSource {
            anchors.fill: parent
            visible: root.angle < 90
            sourceItem: holder
            live: flap.visible && visible
            sourceRect: Qt.rect(flap.x, flap.y, flap.width, flap.height)
        }

        Item {
            anchors.fill: parent
            visible: root.angle >= 90

            Rectangle {
                id: back
                width: root.horizontal ? parent.width : parent.width * root.backFraction
                height: root.horizontal ? parent.height * root.backFraction : parent.height
                color: root.backColor
                radius: root.radius
                Crane {
                    visible: root.stamp
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.42
                    height: width
                    tint: Paper.ink
                    wing: Paper.accent
                    opacity: 0.22
                    rotation: 180
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            radius: root.radius
            opacity: Math.sin(root.angle * Math.PI / 180) * 0.22
        }
    }
}
