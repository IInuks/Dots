import QtQuick
import "../"

// Text whose characters roll individually when they change (clock digits):
// the old glyph slides up and fades, the new one rises from below.
Row {
    id: root

    property string text
    property color color: Theme.text
    property real pixelSize: Theme.fontItem
    property int weight: Font.Medium
    property real letterSpacing: 0
    property int duration: Theme.animSlow

    spacing: letterSpacing

    Repeater {
        model: root.text.length

        Item {
            id: cell
            required property int index
            readonly property string ch: root.text.charAt(index)
            property string last: ch

            width: cur.implicitWidth
            height: cur.implicitHeight
            Behavior on width { NumberAnimation { duration: root.duration; easing.type: Theme.easing } }

            onChChanged: {
                prev.text = last;
                cur.text = ch;
                last = ch;
                roll.restart();
            }

            Txt {
                id: prev
                opacity: 0
                color: root.color
                font.pixelSize: root.pixelSize
                font.weight: root.weight
                elide: Text.ElideNone
            }
            Txt {
                id: cur
                text: cell.ch
                color: root.color
                font.pixelSize: root.pixelSize
                font.weight: root.weight
                elide: Text.ElideNone
            }

            ParallelAnimation {
                id: roll
                NumberAnimation { target: prev; property: "y"; from: 0; to: -cur.implicitHeight * 0.55; duration: root.duration; easing.type: Theme.easing }
                NumberAnimation { target: prev; property: "opacity"; from: 1; to: 0; duration: root.duration * 0.6 }
                NumberAnimation { target: cur; property: "y"; from: cur.implicitHeight * 0.55; to: 0; duration: root.duration; easing.type: Theme.easingSpring; easing.overshoot: 1.2 }
                NumberAnimation { target: cur; property: "opacity"; from: 0; to: 1; duration: root.duration * 0.8 }
            }
        }
    }
}
