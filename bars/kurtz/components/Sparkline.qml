import QtQuick
import QtQuick.Shapes
import "../"

// History line with a soft gradient area underneath. `values` are 0..1.
Item {
    id: root
    property var values: []
    property color color: Theme.accent
    property int capacity: 40

    implicitWidth: 200
    implicitHeight: 50

    readonly property var pts: {
        const out = [];
        const n = root.values.length;
        const step = root.width / Math.max(1, root.capacity - 1);
        const off = root.capacity - n;
        for (let i = 0; i < n; i++)
            out.push(Qt.point((off + i) * step, root.height - 3 - root.values[i] * (root.height - 6)));
        return out;
    }

    Shape {
        anchors.fill: parent
        visible: root.pts.length > 1
        preferredRendererType: Shape.CurveRenderer
        // area
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: root.height
                GradientStop { position: 0; color: Theme.alpha(root.color, 0.35) }
                GradientStop { position: 1; color: Theme.alpha(root.color, 0) }
            }
            PathPolyline {
                path: root.pts.length > 1 ? [Qt.point(root.pts[0].x, root.height)].concat(root.pts).concat([Qt.point(root.pts[root.pts.length - 1].x, root.height)]) : []
            }
        }
        // line
        ShapePath {
            strokeColor: root.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.pts }
        }
    }
    // head dot
    Orb {
        visible: root.pts.length > 0
        width: 9; height: 9
        rim: false
        x: root.pts.length ? root.pts[root.pts.length - 1].x - 4.5 : 0
        y: root.pts.length ? root.pts[root.pts.length - 1].y - 4.5 : 0
        color: root.color
        glowing: true
    }
}
