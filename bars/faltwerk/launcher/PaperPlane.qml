import QtQuick
import QtQuick.Shapes
import "../core"

// Papierflieger: startet dort, wo die App im Launcher lag, faltet sich aus
// einem Quadrat und fliegt in einer Kurve nach oben rechts aus dem Bild.
Item {
    id: root
    required property string screenName

    property real sx: 0
    property real sy: 0
    property color tint: Paper.accent

    Connections {
        target: Falt
        function onLaunched(screen, x, y, tint) {
            if (screen !== root.screenName)
                return;
            root.sx = x;
            root.sy = y;
            root.tint = tint;
            flight.restart();
        }
    }

    // gefaltetes Quadrat, das zum Flieger wird
    Rectangle {
        id: square
        visible: flight.running && opacity > 0
        x: root.sx - 30
        y: root.sy - 30
        width: 60
        height: 60
        radius: 3
        color: root.tint
        opacity: 0
        property real fold: 0
        transform: Rotation {
            origin.x: 30
            origin.y: 30
            axis { x: 1; y: 1; z: 0 }
            angle: square.fold * 90
        }
    }

    Item {
        id: plane
        visible: flight.running
        width: 72
        height: 40
        opacity: 0
        scale: 0.4

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            // obere Tragflaeche
            ShapePath {
                strokeWidth: 1
                strokeColor: Qt.darker(root.tint, 1.3)
                fillColor: Qt.lighter(root.tint, 1.15)
                startX: 0; startY: 6
                PathLine { x: 72; y: 22 }
                PathLine { x: 18; y: 22 }
                PathLine { x: 0; y: 6 }
            }
            // Kiel
            ShapePath {
                strokeWidth: 1
                strokeColor: Qt.darker(root.tint, 1.3)
                fillColor: Qt.darker(root.tint, 1.3)
                startX: 18; startY: 22
                PathLine { x: 72; y: 22 }
                PathLine { x: 26; y: 34 }
                PathLine { x: 18; y: 22 }
            }
            // untere Flaeche
            ShapePath {
                strokeWidth: 1
                strokeColor: Qt.darker(root.tint, 1.3)
                fillColor: root.tint
                startX: 6; startY: 16
                PathLine { x: 72; y: 22 }
                PathLine { x: 18; y: 22 }
                PathLine { x: 6; y: 16 }
            }
        }
    }

    // Kondensstreifen aus Punkten
    Repeater {
        model: 6
        delegate: Rectangle {
            required property int index
            width: 5
            height: 5
            radius: 2.5
            color: root.tint
            visible: flight.running
            property real lag: (index + 1) * 0.035
            x: trail.at(lag).x - 2.5
            y: trail.at(lag).y - 2.5
            opacity: plane.opacity * (1 - index / 6) * 0.7
        }
    }
    QtObject {
        id: trail
        property var points: []
        function at(lag) {
            const pts = points;
            const idx = Math.max(0, pts.length - 1 - Math.round(lag * 60));
            return pts.length ? pts[idx] : Qt.point(-100, -100);
        }
    }
    Connections {
        target: plane
        enabled: flight.running
        function onXChanged() {
            const p = trail.points.slice(-40);
            p.push(Qt.point(plane.x + plane.width / 2, plane.y + plane.height / 2));
            trail.points = p;
        }
    }

    SequentialAnimation {
        id: flight
        ScriptAction { script: trail.points = [] }
        ParallelAnimation {
            NumberAnimation { target: square; property: "opacity"; from: 1; to: 1; duration: 1 }
            NumberAnimation { target: square; property: "fold"; from: 0; to: 1; duration: 240; easing.type: Easing.InQuad }
        }
        ScriptAction { script: square.opacity = 0 }
        ParallelAnimation {
            NumberAnimation { target: plane; property: "opacity"; from: 0; to: 1; duration: 120 }
            NumberAnimation { target: plane; property: "scale"; from: 0.4; to: 1.2; duration: 420; easing.type: Easing.OutBack }
            PathAnimation {
                target: plane
                duration: 1050
                easing.type: Easing.InQuad
                anchorPoint: Qt.point(36, 20)
                orientation: PathAnimation.RightFirst
                orientationEntryDuration: 120
                path: Path {
                    startX: root.sx
                    startY: root.sy
                    PathCubic {
                        x: root.width + 120
                        y: -140
                        control1X: root.sx - 160
                        control1Y: root.sy + 160
                        control2X: root.sx + (root.width - root.sx) * 0.4
                        control2Y: root.sy - 40
                    }
                }
            }
            SequentialAnimation {
                PauseAnimation { duration: 820 }
                NumberAnimation { target: plane; property: "opacity"; to: 0; duration: 230 }
            }
        }
    }
}
