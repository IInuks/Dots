import QtQuick
import QtQuick.Shapes

// Origami-Kranich aus fuenf Flaechen, im 24x24-Raster gezeichnet und auf
// width/height skaliert. Fluegel in `wing`, Koerper in `tint`.
Item {
    id: root
    property color tint: "black"
    property color wing: "red"
    // 0..1: hebt die Fluegel an (fuer den Flatter-Effekt beim Hover)
    property real flap: 0

    implicitWidth: 24
    implicitHeight: 24

    Shape {
        width: 24
        height: 24
        scale: Math.min(root.width, root.height) / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        // hinterer Fluegel
        ShapePath {
            strokeWidth: -1
            fillColor: Qt.darker(root.wing, 1.25)
            startX: 9.5; startY: 12.5
            PathLine { x: 6 - root.flap * 1.5; y: 3 - root.flap * 1 }
            PathLine { x: 12.5; y: 11 }
            PathLine { x: 9.5; y: 12.5 }
        }
        // Koerper
        ShapePath {
            strokeWidth: -1
            fillColor: root.tint
            startX: 7; startY: 14.5
            PathLine { x: 12.5; y: 11 }
            PathLine { x: 17.5; y: 14.5 }
            PathLine { x: 12.5; y: 17 }
            PathLine { x: 7; y: 14.5 }
        }
        // Hals + Kopf
        ShapePath {
            strokeWidth: -1
            fillColor: root.tint
            startX: 7; startY: 14.5
            PathLine { x: 3.2; y: 7.5 }
            PathLine { x: 1.2; y: 9.2 }
            PathLine { x: 3.6; y: 8.8 }
            PathLine { x: 5.6; y: 15 }
            PathLine { x: 7; y: 14.5 }
        }
        // Schwanz
        ShapePath {
            strokeWidth: -1
            fillColor: root.tint
            startX: 17.5; startY: 14.5
            PathLine { x: 22.5; y: 7.5 }
            PathLine { x: 19.2; y: 15 }
            PathLine { x: 17.5; y: 14.5 }
        }
        // vorderer Fluegel
        ShapePath {
            strokeWidth: -1
            fillColor: root.wing
            startX: 12.5; startY: 12
            PathLine { x: 16.5 + root.flap * 1.5; y: 2.5 - root.flap * 1 }
            PathLine { x: 15.5; y: 13.2 }
            PathLine { x: 12.5; y: 12 }
        }
    }
}
