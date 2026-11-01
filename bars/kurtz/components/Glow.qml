import QtQuick
import QtQuick.Shapes
import "../"

// Soft round glow: a radial gradient that fades from `color` to alpha 0.
// Pure vector fill, no layer/blur pass -> cheap enough to use many times.
// Place it *behind* the glowing object and size it ~1.6-2.4x larger.
Shape {
    id: root
    property color color: Theme.accent
    property real strength: 1.0 // multiplied with Theme.glow

    readonly property real _r: Math.min(width, height) / 2
    preferredRendererType: Shape.CurveRenderer
    opacity: Theme.glow * strength
    visible: opacity > 0.01

    ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: root.width / 2
            centerY: root.height / 2
            centerRadius: root._r
            focalX: centerX
            focalY: centerY
            GradientStop { position: 0.0; color: Theme.alpha(root.color, 0.55) }
            GradientStop { position: 0.35; color: Theme.alpha(root.color, 0.22) }
            GradientStop { position: 1.0; color: Theme.alpha(root.color, 0.0) }
        }
        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root._r
            radiusY: root._r
            startAngle: 0
            sweepAngle: 360
        }
    }
}
