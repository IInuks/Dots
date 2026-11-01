import QtQuick
import "../"

// 6px track, accent fill, round 16px accent handle. `value` is 0..1.
// Glides to outside value changes, follows the pointer directly while dragging.
Item {
    id: root

    property real value: 0
    property bool enabled_: true
    readonly property bool dragging: mouse.pressed

    signal moved(real value)

    implicitHeight: 16
    implicitWidth: 200
    opacity: enabled_ ? 1 : 0.45
    Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown {
        enabled: !root.dragging
        NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingEmph }
    }

    // grows from the left once when created
    property real grow: 0
    NumberAnimation on grow { from: 0; to: 1; duration: 600; easing.type: Theme.easingEmph }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        width: parent.width - 16
        height: mouse.containsMouse || root.dragging ? 8 : 6
        radius: height / 2
        color: Theme.track
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

        Rectangle {
            width: track.width * root.shown * root.grow
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    Rectangle {
        id: handle
        width: 16
        height: 16
        radius: 8
        color: Theme.accent
        anchors.verticalCenter: parent.verticalCenter
        x: track.x + track.width * root.shown * root.grow - width / 2
        scale: root.dragging ? 1.35 : mouse.containsMouse ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }

        // soft halo while dragging
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 2
            height: width
            radius: width / 2
            color: Theme.accent
            opacity: root.dragging ? 0.22 : 0
            scale: root.dragging ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
            Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled_
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function emit(mx) {
            root.moved(Math.max(0, Math.min(1, (mx - track.x) / track.width)));
        }
        onPressed: e => emit(e.x)
        onPositionChanged: e => { if (pressed) emit(e.x); }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
