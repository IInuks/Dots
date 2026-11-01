import QtQuick
import QtQuick.Shapes
import ".."

// Small magnifier glyph, drawn (not an emoji/font icon) so it stays in the
// same brass-instrument stroke style as the gauges. Shown in the clock
// module while the launcher is open, in place of the time.
Item {
    id: root
    implicitWidth: 15
    implicitHeight: 15
    property color color: Theme.panelInk

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: root.color
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 6
                centerY: 6
                radiusX: 4.5
                radiusY: 4.5
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: 1.6
            capStyle: ShapePath.RoundCap
            startX: 9.3
            startY: 9.3
            PathLine {
                x: 13.5
                y: 13.5
            }
        }
    }
}
