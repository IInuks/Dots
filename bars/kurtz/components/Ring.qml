import QtQuick
import QtQuick.Shapes
import "../"

// Thick round-capped progress ring. Track + value arc, starting at 12
// o'clock. Children are centered inside (put the number/icon there).
// Strokes are allowed here: rings are functional (style guide section 2).
Item {
    id: root

    property real value: 0             // 0..1
    property color color: Theme.accent
    property color trackColor: Theme.alpha(Theme.text, 0.08)
    property real thickness: Math.max(2.5, width * 0.12)
    property bool glowing: false
    property bool animated: true       // ease value changes
    default property alias content: inner.data

    readonly property real _v: Math.max(0, Math.min(1, value))
    property real _anim: _v
    Behavior on _anim {
        enabled: root.animated
        NumberAnimation { duration: Theme.tSlow * 2; easing.type: Theme.easeOut }
    }

    implicitWidth: 32
    implicitHeight: 32

    Glow {
        anchors.centerIn: parent
        width: root.width * 1.7
        height: width
        color: root.color
        strength: root.glowing ? 0.6 : 0
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root._anim > 0.001 ? root.thickness : 0
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * root._anim
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
