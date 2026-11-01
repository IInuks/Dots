import QtQuick
import QtQuick.Shapes
import "../"

// The glass body every panel is drawn with: diagonal olive→plum gradient, hairline
// border, rounded corners. Mango blurs only the non-transparent pixels of a layer,
// so the blur follows this exact rounded shape.
Item {
    id: root

    property real radius: Theme.radiusPanel
    property color fromColor: Theme.panelFrom
    property color toColor: Theme.panelTo
    property color borderColor: Theme.border
    property bool bordered: true

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.bordered ? 1 : 0
            strokeColor: root.bordered ? root.borderColor : "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: root.width; y2: root.height
                GradientStop { position: 0; color: root.fromColor }
                GradientStop { position: 1; color: root.toColor }
            }

            PathRectangle {
                x: 0.5; y: 0.5
                width: root.width - 1
                height: root.height - 1
                radius: root.radius
            }
        }
    }
}
