import QtQuick
import QtQuick.Shapes
import "../"

// Rounded slider: sunken capsule track, accent-gradient fill, shaded Orb
// knob that squashes while dragged. Click, drag or scroll.
Item {
    id: root

    property real value: 0.5          // 0..1
    property real from: 0
    property real to: 1
    property real step: 0             // 0 = continuous
    property color color: Theme.accent
    property color color2: Theme.accent2
    property string glyph: ""
    property real trackHeight: 12

    signal moved(real v)              // emitted on user interaction only

    implicitWidth: 200
    implicitHeight: 28

    readonly property real _t: (value - from) / Math.max(0.0001, to - from)
    readonly property real _knob: height * 0.86
    readonly property real _x0: _knob / 2
    readonly property real _w: width - _knob

    function _setFromX(px) {
        let t = Math.max(0, Math.min(1, (px - _x0) / _w));
        let v = from + t * (to - from);
        if (step > 0)
            v = Math.round(v / step) * step;
        root.moved(v);
    }

    // track
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: root._x0 - root.trackHeight / 2
        width: root._w + root.trackHeight
        height: root.trackHeight
        radius: height / 2
        color: Theme.surfaceSunken
    }
    // fill
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: track.x
        width: Math.max(track.height, root._t * root._w + root.trackHeight)
        height: root.trackHeight
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.color2 }
            GradientStop { position: 1.0; color: root.color }
        }
        Behavior on width {
            enabled: !mouse.pressed
            NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut }
        }
    }
    KIcon {
        visible: root.glyph !== ""
        text: root.glyph
        size: root.trackHeight * 0.95
        x: track.x + root.trackHeight * 0.4
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.bgTop
        opacity: root._t > 0.12 ? 0.85 : 0
    }

    // knob
    Orb {
        id: knob
        width: root._knob
        height: root._knob
        anchors.verticalCenter: parent.verticalCenter
        x: root._t * root._w
        color: root.color
        glowing: mouse.containsMouse || mouse.pressed
        glowStrength: 0.7
        squash: mouse.pressed ? 0.86 : 1
        Behavior on squash { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: 2 } }
        Behavior on x {
            enabled: !mouse.pressed
            NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: m => root._setFromX(m.x)
        onPositionChanged: m => { if (pressed) root._setFromX(m.x); }
        onWheel: e => {
            const d = (root.step > 0 ? root.step : (root.to - root.from) / 20) * (e.angleDelta.y > 0 ? 1 : -1);
            root.moved(Math.max(root.from, Math.min(root.to, root.value + d)));
        }
    }
}
