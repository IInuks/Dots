import QtQuick
import ".."

// Minimal 0..1-normalized slider with a label + value readout, used for
// opacity/radius in the theme editor. Same drag-anywhere-on-track approach
// as bars/floating/right/SliderRow.qml, rebuilt slim for this panel.
Column {
    id: root

    property string label: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property string suffix: ""

    signal moved(real value)

    readonly property real _t: root.to > root.from ? (root.value - root.from) / (root.to - root.from) : 0

    spacing: 3
    width: parent ? parent.width : 160

    Row {
        width: root.width
        Text {
            width: parent.width - valueText.width
            text: root.label
            color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.6)
            font.pixelSize: 10
        }
        Text {
            id: valueText
            text: Math.round(root.value * (root.suffix === "%" ? 100 : 1)) + root.suffix
            color: Theme.foreground
            font.pixelSize: 10
        }
    }

    Item {
        width: root.width
        height: 14

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, root._t))
            height: 4
            radius: 2
            color: Theme.accent
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            cursorShape: Qt.PointingHandCursor
            function apply(mx) {
                const t = Math.max(0, Math.min(1, mx / width));
                root.moved(root.from + t * (root.to - root.from));
            }
            onPressed: mouse => apply(mouse.x)
            onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
        }
    }
}
