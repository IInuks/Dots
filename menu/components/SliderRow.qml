import QtQuick
import ".."

// Label + value readout + slider. value is bound from outside; dragging
// emits moved() on every step and the owner writes it back (BlobStore
// coalesces the file writes).
Item {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property int decimals: 0
    property string suffix: ""
    signal moved(real value)

    implicitWidth: 300
    implicitHeight: 40
    opacity: enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    readonly property real _ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    Text {
        anchors.left: parent.left
        anchors.right: valueText.left
        anchors.top: parent.top
        elide: Text.ElideRight
        text: root.label
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontM
    }
    Text {
        id: valueText
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Theme.textDim
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontS
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        height: 6
        radius: height / 2
        color: Theme.panelAlt
        border.width: Theme.borderWidth
        border.color: Theme.border

        Rectangle {
            width: Math.max(height, track.width * root._ratio)
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: (track.height - height) / 2
            x: Math.max(0, Math.min(track.width - width, track.width * root._ratio - width / 2))
            color: Theme.text
            border.width: 2
            border.color: Theme.accent
            scale: mouse.pressed ? 1.2 : (mouse.containsMouse ? 1.08 : 1)
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -9
            hoverEnabled: true
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            function apply(mx) {
                const t = Math.max(0, Math.min(1, (mx - 9) / track.width));
                const step = Math.pow(10, root.decimals);
                root.moved(Math.round((root.from + t * (root.to - root.from)) * step) / step);
            }
            onPressed: e => apply(e.x)
            onPositionChanged: e => { if (pressed) apply(e.x); }
        }
    }
}
