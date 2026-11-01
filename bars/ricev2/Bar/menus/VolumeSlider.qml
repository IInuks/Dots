import QtQuick
import "../../"

// Per-device volume slider (menus prompt 1.1): 14px tall hit area, 4px
// track (radius 2, primary @ 0.18) with a primary fill, a 10x10 round primary
// knob (1px surface @ 0.85 ring) that scales to 1.25 on hover/drag (120ms
// OutCubic). The click/drag area is 6px taller than the visible slider.
// While dragging, the knob follows the mouse locally instead of the bound
// `value` (which only updates on every native volume-change signal) so nothing
// visibly snaps back mid-drag.
Item {
    id: root

    property real value: 0 // 0..1, bound from the caller (e.g. sink.audio.volume)
    signal moved(real v)

    implicitHeight: 14
    implicitWidth: 200

    readonly property bool _dragging: handleDrag.drag.active
    readonly property real _displayValue: root._dragging ? root._localValue : root.value
    property real _localValue: root.value

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root._displayValue))
            height: track.height
            radius: track.radius
            color: Colors.primary
        }
    }

    Rectangle {
        id: handle
        width: 10
        height: 10
        radius: 5
        color: Colors.primary
        border.width: 1
        border.color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.85)
        x: Math.max(0, Math.min(track.width, track.width * root._displayValue)) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        scale: (hoverHandler.hovered || root._dragging) ? 1.25 : 1.0

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        id: handleDrag
        anchors.fill: parent
        anchors.topMargin: -3
        anchors.bottomMargin: -3
        hoverEnabled: true
        // A dummy drag target purely so `drag.active` gives us a reliable
        // "currently dragging" flag (for the knob scale-up and the
        // local-value override above) -- the actual value comes from
        // mouse.x below, not from this proxy's position.
        drag.target: dragProxy
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: root.width

        Item {
            id: dragProxy
            x: 0
        }

        onPressed: mouse => {
            const v = Math.max(0, Math.min(1, mouse.x / root.width));
            root._localValue = v;
            root.moved(v);
            dragProxy.x = mouse.x;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const v = Math.max(0, Math.min(1, mouse.x / root.width));
            root._localValue = v;
            root.moved(v);
        }
    }
}
