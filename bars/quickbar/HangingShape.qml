import QtQuick
import QtQuick.Shapes

// A shape that "hangs" from whatever edge it's attached to: flat top flush
// against that edge, with the top corners flaring outward via an inverted
// (concave) curve -- like a MacBook notch, just wider -- and normal convex
// rounding at the bottom. Used for the bar itself (hanging from the screen
// top) and every drop-menu (hanging from the bar's bottom edge).
Shape {
    id: root

    property real bodyWidth: 580
    property real bodyHeight: 48
    property real flareW: 30
    property real flareH: 22
    property real bottomRadius: 22
    property color fillColor: "#000000"

    width: bodyWidth + 2 * flareW
    height: bodyHeight
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeWidth: -1
        startX: 0; startY: 0

        // top edge (flush with the edge this shape hangs from)
        PathLine { x: root.width; y: 0 }

        // right flare: concave, curving down from the top edge to the
        // right side edge
        PathCubic {
            x: root.width - root.flareW; y: root.flareH
            control1X: root.width - root.flareW * 0.67; control1Y: 0
            control2X: root.width - root.flareW;         control2Y: root.flareH * 0.36
        }

        // right side edge
        PathLine { x: root.width - root.flareW; y: root.bodyHeight - root.bottomRadius }

        // bottom-right corner (convex)
        PathArc {
            x: root.width - root.flareW - root.bottomRadius; y: root.bodyHeight
            radiusX: root.bottomRadius; radiusY: root.bottomRadius
        }

        // bottom edge
        PathLine { x: root.flareW + root.bottomRadius; y: root.bodyHeight }

        // bottom-left corner (convex)
        PathArc {
            x: root.flareW; y: root.bodyHeight - root.bottomRadius
            radiusX: root.bottomRadius; radiusY: root.bottomRadius
        }

        // left side edge
        PathLine { x: root.flareW; y: root.flareH }

        // left flare: concave, curving back up to the top edge
        PathCubic {
            x: 0; y: 0
            control1X: root.flareW;        control1Y: root.flareH * 0.36
            control2X: root.flareW * 0.67; control2Y: 0
        }
    }
}
