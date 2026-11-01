import QtQuick
import QtQuick.Shapes
import "../"

// The signature Kurzgesagt "soft-3D" sphere, built only from flat layers.
// Light comes from the UPPER-LEFT, always.
//
//        .-""""-.          layer 0  glow      radial fade behind (optional)
//      .'  (h)   '.        layer 1  shadow    full disc, dark + blue-shifted
//     /  base     \        layer 2  base      smaller disc, internally tangent
//    |             |)                          at the upper-left -> what stays
//     \           /))                          visible of layer 1 is a crisp
//      '.       .'))                           crescent on the lower-right
//        '-....-'))        layer 3  highlight small light patch upper-left
//                          layer 4  rim       thin bright arc on the shadow side
//                          layer 5  ring      optional planet ring (back+front)
//
// No clipping or masks are needed: layer 2 is geometrically inside layer 1.
// All tones are derived from `color` via Theme.shadeOf/highlightOf/rimOf, so
// every orb in the shell shades identically.
Item {
    id: root

    property color color: Theme.accent
    property bool glowing: false
    property real glowStrength: 1.0
    property real glowSize: 2.1        // glow diameter / orb diameter
    property bool highlight: true
    property bool rim: diameter >= 12
    property bool ring: false          // saturn-style ring
    property color ringColor: Theme.highlightOf(color)
    property real crescent: 0.16       // shadow thickness as fraction of radius*2

    // Squash & stretch hook: set <1 / >1 to squish vertically.
    property real squash: 1.0

    readonly property real diameter: Math.min(width, height)
    readonly property real _R: diameter / 2
    readonly property real _r: _R * (1 - crescent)
    // Offset of the lit disc towards the light (upper-left, 45 deg).
    readonly property real _off: (_R - _r) * 0.7071

    implicitWidth: 24
    implicitHeight: 24

    Behavior on color {
        ColorAnimation { duration: Theme.tMed; easing.type: Theme.easeOut }
    }

    // ---- layer 0: glow
    Glow {
        anchors.centerIn: body
        width: root.diameter * root.glowSize
        height: width
        color: root.color
        strength: root.glowing ? root.glowStrength : 0
        Behavior on strength {
            NumberAnimation { duration: Theme.tSlow; easing.type: Theme.easeOut }
        }
    }

    // Back half of the planet ring (drawn before the body).
    Loader {
        active: root.ring
        anchors.centerIn: body
        sourceComponent: ringHalf
        onLoaded: item.front = false
    }

    Item {
        id: body
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        transform: Scale {
            origin.x: body.width / 2
            origin.y: body.height
            yScale: root.squash
            xScale: 1 + (1 - root.squash) * 0.6
        }

        // ---- layer 1: shadow body
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.shadeOf(root.color)
            antialiasing: true
        }

        // ---- layer 2: lit base, tangent to the outline at the upper-left
        Rectangle {
            width: root._r * 2
            height: width
            radius: width / 2
            x: root._R - root._r - root._off
            y: root._R - root._r - root._off
            color: root.color
            antialiasing: true
        }

        // ---- layer 3: highlight patch (a rotated rounded capsule) + dot
        Rectangle {
            visible: root.highlight && root.diameter >= 8
            width: root.diameter * 0.30
            height: root.diameter * 0.15
            radius: height / 2
            x: root.diameter * 0.17
            y: root.diameter * 0.22
            rotation: -45
            color: Theme.highlightOf(root.color)
            opacity: 0.9
            antialiasing: true
        }
        Rectangle {
            visible: root.highlight && root.diameter >= 18
            width: root.diameter * 0.07
            height: width
            radius: width / 2
            x: root.diameter * 0.44
            y: root.diameter * 0.13
            color: Theme.highlightOf(root.color)
            opacity: 0.8
        }

        // ---- layer 4: rim light hugging the lower-right edge
        Shape {
            visible: root.rim
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.rimOf(root.color)
                strokeWidth: Math.max(1, root.diameter * 0.045)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root._R
                    centerY: root._R
                    radiusX: root._R - Math.max(1, root.diameter * 0.045) * 1.6
                    radiusY: radiusX
                    startAngle: 15      // 0 = 3 o'clock, clockwise
                    sweepAngle: 60
                }
            }
        }
    }

    // Front half of the planet ring (drawn over the body).
    Loader {
        active: root.ring
        anchors.centerIn: body
        sourceComponent: ringHalf
        onLoaded: item.front = true
    }

    Component {
        id: ringHalf
        Shape {
            id: ringShape
            property bool front: true
            width: root.diameter * 1.9
            height: root.diameter * 0.62
            rotation: -18
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.ringColor
                strokeWidth: Math.max(1.5, root.diameter * 0.08)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.diameter * 0.95
                    centerY: root.diameter * 0.31
                    radiusX: root.diameter * 0.9
                    radiusY: root.diameter * 0.26
                    // Lower half (0..180) passes in front of the planet.
                    startAngle: ringShape.front ? 8 : 188
                    sweepAngle: 164
                }
            }
        }
    }
}
