import QtQuick
import QtQuick.Shapes
import ".."

// Fortschrittsring der rechten Kugel (Auftrag Abschnitt 6). 8-Uhr- bis
// 4-Uhr-Position, im Uhrzeigersinn ueber oben (240 Grad, 120 Grad Luecke
// unten). Winkel in Qt-Konvention: 0 Grad = 3-Uhr-Position, positiv =
// im Uhrzeigersinn -- 8 Uhr = 150 Grad, 4 Uhr = 30 Grad; von 150 Grad aus
// im Uhrzeigersinn (+240) ueber 9/12/3 Uhr laeuft exakt auf 30 Grad (4 Uhr).
Item {
    id: root

    property real progress: 0 // 0..1, bereits geklemmt vom Aufrufer
    property color statusColor: Theme.primary

    readonly property real _strokeWidth: 2.5
    // Bleibt innerhalb der 46x46 -- die Kugel wird durch den Ring nicht
    // groesser (Auftrag Abschnitt 6).
    readonly property real _radius: Math.min(width, height) / 2 - _strokeWidth / 2 - 1

    Behavior on progress {
        NumberAnimation {
            duration: Theme.durRingFill
            easing.type: Theme.easeMorph
        }
    }
    Behavior on statusColor {
        ColorAnimation {
            duration: Theme.durRingFill
        }
    }

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeColor: Theme.outline
            strokeWidth: root._strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: 150
                sweepAngle: 240
            }
        }

        ShapePath {
            strokeColor: root.statusColor
            strokeWidth: root._strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: 150
                sweepAngle: 240 * root.progress
            }
        }
    }
}
