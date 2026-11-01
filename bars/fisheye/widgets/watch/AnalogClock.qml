import QtQuick
import QtQuick.Shapes
import Quickshell
import "../.."

// Etappe 7: the analog watch face, opened from ClockModule's popup. Round
// dial + ticks + three hands (all QtQuick primitives, no Shapes needed --
// a circle is just Rectangle.radius and a hand is just a rotated bar), plus
// one Canvas for the curved ring text along the bottom arc -- the single
// spot in this project where Canvas draws text instead of a font-free
// segment widget, per the Konventionen exception carved out for exactly
// this ("Canvas nur für den gebogenen Ringtext der Analoguhr").
Item {
    id: root

    property real size: 132
    implicitWidth: size
    implicitHeight: size

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property real _hourAngle: ((clock.hours % 12) + clock.minutes / 60) * 30
    readonly property real _minuteAngle: (clock.minutes + clock.seconds / 60) * 6
    readonly property real _secondAngle: clock.seconds * 6

    // Dial face. Not LcdSurface -- its pixel-grid texture is drawn into a
    // square Canvas and would bleed past the circle into this Item's
    // corners since QML clip only clips to the bounding rect, not to
    // Rectangle.radius.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surface
    }

    // Two-tone bezel ring: light arc upper-left, dark arc lower-right --
    // same headroom-relative bevel colors BevelPanel uses, just traced as
    // a ring instead of four straight strips since the dial is round.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 0.5
        radius: width / 2
        color: "transparent"
        border.width: 1.5
        border.color: Theme.bevelDark
    }
    Shape {
        anchors.fill: parent
        antialiasing: true
        ShapePath {
            strokeColor: Theme.bevelLight
            strokeWidth: 1.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 1
                radiusY: root.size / 2 - 1
                startAngle: 135
                sweepAngle: 180
            }
        }
    }

    // Ring text: curved along the bottom arc, following a real quartz
    // analog watch's habit of printing its movement type under center.
    // Redrawn on palette swap since Theme.surfaceInk isn't a static value.
    Canvas {
        id: ringText
        anchors.fill: parent
        readonly property color inkColor: Theme.surfaceInk
        readonly property string label: "QUARTZ"
        onInkColorChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const cx = width / 2, cy = height / 2;
            const r = root.size * 0.32;
            const anglePerChar = 15 * Math.PI / 180;
            const total = anglePerChar * (label.length - 1);
            let angle = Math.PI / 2 - total / 2;
            ctx.fillStyle = inkColor;
            ctx.globalAlpha = 0.55;
            ctx.font = Math.max(1, Math.round(root.size * 0.075)) + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            for (const ch of label) {
                const x = cx + r * Math.cos(angle);
                const y = cy + r * Math.sin(angle);
                ctx.save();
                ctx.translate(x, y);
                ctx.rotate(angle + Math.PI / 2);
                ctx.fillText(ch, 0, 0);
                ctx.restore();
                angle += anglePerChar;
            }
        }
    }

    // Hour ticks, major (12/3/6/9) heavier than the rest. Positioned by
    // trig instead of Repeater+transformOrigin math: index 0 sits at -90°
    // (12 o'clock) with rotation 0 (an unrotated bar is already vertical),
    // and both the position angle and the rotation angle grow together by
    // 30° per step, so they stay lined up without a separate offset.
    Repeater {
        model: 12
        delegate: Rectangle {
            required property int index
            readonly property real angle: index * 30 - 90
            readonly property bool major: index % 3 === 0
            width: major ? 3 : 1.5
            height: major ? 11 : 6
            radius: width / 2
            color: Theme.surfaceInk
            opacity: major ? 0.85 : 0.4
            readonly property real _r: root.size / 2 - height / 2 - 4
            x: root.size / 2 + _r * Math.cos(angle * Math.PI / 180) - width / 2
            y: root.size / 2 + _r * Math.sin(angle * Math.PI / 180) - height / 2
            rotation: index * 30
        }
    }

    // Hands. No Behavior on rotation: the wrap from 354° back to 0° once
    // an hour/minute/60s would animate a full backwards sweep through 180°
    // (feedback_qml_animation_on_bound_property.md is the same family of
    // bug, an animation fighting a value that legitimately jumps) -- and a
    // hard per-second tick is period-correct for a quartz movement anyway,
    // unlike a sweeping mechanical second hand.
    Rectangle {
        width: 4
        height: root.size * 0.28
        radius: width / 2
        color: Theme.surfaceInk
        x: root.size / 2 - width / 2
        y: root.size / 2 - height
        transformOrigin: Item.Bottom
        rotation: root._hourAngle
    }
    Rectangle {
        width: 3
        height: root.size * 0.4
        radius: width / 2
        color: Theme.surfaceInk
        x: root.size / 2 - width / 2
        y: root.size / 2 - height
        transformOrigin: Item.Bottom
        rotation: root._minuteAngle
    }
    Rectangle {
        width: 1.5
        height: root.size * 0.44
        radius: width / 2
        color: Theme.critical
        x: root.size / 2 - width / 2
        y: root.size / 2 - height
        transformOrigin: Item.Bottom
        rotation: root._secondAngle
    }

    Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.centerIn: parent
        color: Theme.accent
    }
}
