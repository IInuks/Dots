import QtQuick
import "../.."

// Rundes Steuerfeld mit ziehbarem Knauf. Richtung + Auslenkung (0..1) des
// Knaufs relativ zur Mitte werden als vx/vy gemeldet -- SpiderController
// nutzt das direkt als Bewegungsvektor. Loslassen springt sofort in die
// Mitte zurueck (kein Sticky-Steuerknueppel).
Item {
    id: root

    property bool joystickEnabled: true
    signal vectorChanged(real vx, real vy)

    readonly property real _radius: Settings.spiderJoystickSize / 2
    readonly property real _knobRadius: Settings.spiderJoystickKnobSize / 2
    property real _knobX: 0
    property real _knobY: 0
    property bool _dragging: false

    implicitWidth: Settings.spiderJoystickSize
    implicitHeight: Settings.spiderJoystickSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Colors.panelAlt
        border.color: Colors.divider
        border.width: 1
    }

    Rectangle {
        id: knob
        width: Settings.spiderJoystickKnobSize
        height: width
        radius: width / 2
        color: root._dragging ? Colors.accent : Colors.accentAlt
        border.color: Colors.divider
        border.width: 1
        antialiasing: true
        x: root._radius + root._knobX - width / 2
        y: root._radius + root._knobY - height / 2

        Behavior on x {
            enabled: !root._dragging
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutBack
            }
        }
        Behavior on y {
            enabled: !root._dragging
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutBack
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.joystickEnabled
        onPressed: mouse => root._drag(mouse.x, mouse.y)
        onPositionChanged: mouse => {
            if (pressed)
                root._drag(mouse.x, mouse.y);
        }
        onReleased: root._release()
        onCanceled: root._release()
    }

    function _drag(px, py) {
        root._dragging = true;
        let dx = px - root._radius;
        let dy = py - root._radius;
        const dist = Math.hypot(dx, dy);
        const maxDist = root._radius - root._knobRadius * 0.5;
        if (dist > maxDist && dist > 0) {
            dx = dx / dist * maxDist;
            dy = dy / dist * maxDist;
        }
        root._knobX = dx;
        root._knobY = dy;
        root.vectorChanged(dx / maxDist, dy / maxDist);
    }

    function _release() {
        root._dragging = false;
        root._knobX = 0;
        root._knobY = 0;
        root.vectorChanged(0, 0);
    }
}
