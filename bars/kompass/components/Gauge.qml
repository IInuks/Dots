import QtQuick
import QtQuick.Shapes
import ".."

// Generic circular needle instrument (CPU temp now, reusable later for RAM
// etc). 240 degree sweep, 8 o'clock to 4 o'clock, gap at the bottom -- same
// angle convention as bars/blobs/components/TempRing.qml (0 deg = 3 o'clock,
// positive = clockwise): startAngle 150, sweepAngle 240 lands on 30
// (=390 mod 360).
Item {
    id: root

    property real value: 0 // 0..1, already normalized by the caller
    // Cumulative zone boundaries in the same 0..1 space, strictly
    // increasing, last entry's upTo must be 1 -- e.g.
    // [{upTo:0.55, color:Theme.zoneGood}, {upTo:0.8, color:Theme.zoneWarn},
    //  {upTo:1, color:Theme.zoneCritical}]
    property var zones: []

    readonly property real _startAngle: 150
    readonly property real _sweep: 240
    readonly property real _cx: width / 2
    readonly property real _cy: height / 2
    readonly property real _faceRadius: Math.min(width, height) / 2 - 1
    readonly property real _zoneRadius: _faceRadius - 2
    readonly property real _needleLen: _faceRadius - 3

    Behavior on value {
        NumberAnimation {
            duration: Theme.durNeedle
            easing.type: Theme.easeOut
        }
    }

    // Face
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.dialFace
        border.color: Theme.dialRim
        border.width: 1
    }

    // Zone bands -- three fixed ShapePaths, not a Repeater<ShapePath>: a
    // Repeater delegate must be an Item, and ShapePath isn't one (silent
    // "Unable to assign undefined" cascade if you try). root.zones is
    // always exactly 3 entries from the caller; _zoneFrom/_zoneTo/
    // _zoneColor degrade to a zero-length, invisible arc if a slot is
    // missing rather than erroring.
    function _zoneFrom(i) {
        return i === 0 ? 0 : (root.zones[i - 1] ? root.zones[i - 1].upTo : 0);
    }
    function _zoneTo(i) {
        return root.zones[i] ? root.zones[i].upTo : _zoneFrom(i);
    }
    function _zoneColor(i) {
        return root.zones[i] ? root.zones[i].color : "transparent";
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: root._zoneColor(0)
            strokeWidth: 2.5
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root._cx
                centerY: root._cy
                radiusX: root._zoneRadius
                radiusY: root._zoneRadius
                startAngle: root._startAngle + root._sweep * root._zoneFrom(0)
                sweepAngle: root._sweep * (root._zoneTo(0) - root._zoneFrom(0))
            }
        }
        ShapePath {
            strokeColor: root._zoneColor(1)
            strokeWidth: 2.5
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root._cx
                centerY: root._cy
                radiusX: root._zoneRadius
                radiusY: root._zoneRadius
                startAngle: root._startAngle + root._sweep * root._zoneFrom(1)
                sweepAngle: root._sweep * (root._zoneTo(1) - root._zoneFrom(1))
            }
        }
        ShapePath {
            strokeColor: root._zoneColor(2)
            strokeWidth: 2.5
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root._cx
                centerY: root._cy
                radiusX: root._zoneRadius
                radiusY: root._zoneRadius
                startAngle: root._startAngle + root._sweep * root._zoneFrom(2)
                sweepAngle: root._sweep * (root._zoneTo(2) - root._zoneFrom(2))
            }
        }
    }

    // Needle -- tip position computed straight from the angle, no
    // rotation-convention translation needed since it's drawn directly
    // via cos/sin at that angle.
    Shape {
        anchors.fill: parent
        ShapePath {
            startX: root._cx
            startY: root._cy
            strokeColor: Theme.needleColor
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathLine {
                readonly property real _angleRad: (root._startAngle + root._sweep * root.value) * Math.PI / 180
                x: root._cx + root._needleLen * Math.cos(_angleRad)
                y: root._cy + root._needleLen * Math.sin(_angleRad)
            }
        }
    }

    Rectangle {
        width: 5
        height: 5
        radius: 2.5
        anchors.centerIn: parent
        color: Theme.needleHub
    }
}
