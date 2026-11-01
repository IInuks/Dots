import QtQuick
import "../"

// Minimal drag/wheel slider, no QtQuick.Controls dependency -- same house
// style as TextField.qml. `value` is driven by the caller (the real data
// source, e.g. Pipewire audio.volume); dragging/scrolling only emits
// `moved`, the caller writes it back into the source, which flows back into
// `value` -- avoids a two-way-binding feedback loop against a live service.
Item {
    id: root

    property real value: 0 // 0..1, always clamped to [min, max]
    property real min: 0
    property real max: 1
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 24

    readonly property real _ratio: root.max > root.min ? Math.max(0, Math.min(1, (root.value - root.min) / (root.max - root.min))) : 0

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.surfaceVariant

        Rectangle {
            width: track.width * root._ratio
            height: parent.height
            radius: parent.radius
            color: root.enabled ? Theme.primary : Theme.outline
            Behavior on width {
                enabled: !dragArea.pressed
                NumberAnimation { duration: Theme.durFast }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.enabled
        onPositionChanged: mouse => { if (pressed) root._setFromX(mouse.x); }
        onPressed: mouse => root._setFromX(mouse.x)
        onWheel: wheel => {
            const step = (root.max - root.min) * 0.05;
            const dir = wheel.angleDelta.y > 0 ? step : -step;
            root.moved(Math.max(root.min, Math.min(root.max, root.value + dir)));
        }
    }

    function _setFromX(x) {
        const ratio = Math.max(0, Math.min(1, x / root.width));
        root.moved(root.min + ratio * (root.max - root.min));
    }
}
