import QtQuick
import "../core"

// Leporello-Faltung: der Inhalt wird in `segments` Streifen geschnitten, die
// abwechselnd nach vorn und hinten kippen (echte Zieharmonika mit
// Perspektive aus Rotation). progress 0 = zusammengefaltet, 1 = flach.
// Solange gefaltet wird, sieht man Kopien (ShaderEffectSource) -- ist das
// Blatt flach, wieder den echten, klickbaren Inhalt.
Item {
    id: root

    property real progress: 1
    property int segments: 3
    property bool vertical: true
    property real shade: Paper.dark ? 0.55 : 0.32
    default property alias content: holder.data

    readonly property real _p: Math.max(0, Math.min(1, progress))
    readonly property bool flat: _p >= 0.999
    readonly property bool hidden: _p <= 0.001
    readonly property real angle: (1 - _p) * 89
    readonly property real cosA: Math.cos(angle * Math.PI / 180)
    readonly property real segLen: (vertical ? height : width) / segments
    // So lang ist das Blatt gerade sichtbar (fuer Schatten/Positionierung).
    readonly property real visibleLength: segLen * cosA * segments

    Item {
        id: holder
        width: root.width
        height: root.height
        visible: !root.hidden
    }

    Repeater {
        model: root.segments
        delegate: Item {
            id: strip
            required property int index
            readonly property bool odd: index % 2 === 1
            readonly property real from: index * root.segLen

            visible: !root.flat && !root.hidden
            x: root.vertical ? 0 : index * root.segLen * root.cosA
            y: root.vertical ? index * root.segLen * root.cosA : 0
            width: root.vertical ? root.width : root.segLen
            height: root.vertical ? root.segLen : root.height

            transform: Rotation {
                origin.x: 0
                origin.y: 0
                axis.x: root.vertical ? 1 : 0
                axis.y: root.vertical ? 0 : 1
                axis.z: 0
                angle: (strip.odd ? -1 : 1) * root.angle
            }

            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: holder
                hideSource: !root.flat
                live: strip.visible
                sourceRect: root.vertical ? Qt.rect(0, strip.from, root.width, root.segLen) : Qt.rect(strip.from, 0, root.segLen, root.height)
            }
            // Knick-Schattierung: die vom Licht abgewandten Streifen dunkler
            Rectangle {
                anchors.fill: parent
                color: strip.odd ? "#000000" : "#ffffff"
                opacity: Math.sin(root.angle * Math.PI / 180) * (strip.odd ? root.shade : 0.10)
            }
        }
    }
}
