import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../"

// A large "sky" surface: soft drop shadow, diagonal night gradient, and a
// decor layer (nebula glows, stars, film grain) clipped to the rounded
// shape. Used by the bar capsule(s), every popup card and the launcher.
//
// Depth layers:  shadow  ->  gradient  ->  [nebula + stars + grain]  ->  content (siblings)
Item {
    id: root

    property real radius: Theme.rLarge
    property real fillAlpha: 0.95
    property bool decor: true
    property int starCount: Theme.c.starCount
    property int seed: 1
    property bool nebula: true
    property bool sparkles: true
    property bool twinkle: true
    property bool shadow: true
    property bool active: visible
    property color tint: "transparent"   // optional accent wash (e.g. urgent toast)

    // ---- outer soft shadow (+ a faint accent glow around it)
    RectangularShadow {
        visible: root.shadow
        anchors.fill: parent
        radius: root.radius
        blur: 26
        spread: 2
        offset.y: Theme.barTop ? 6 : -6
        color: Theme.alpha(Theme.shadowColor, 0.6)
    }
    RectangularShadow {
        visible: root.shadow && Theme.glow > 0.05
        anchors.fill: parent
        radius: root.radius
        blur: 22
        spread: 0
        color: Theme.alpha(Theme.accent, 0.10 * Theme.glow)
    }

    // ---- night gradient, upper-left light -> lower-right deep violet
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: root.width
                y2: root.height * 1.6
                GradientStop { position: 0.0; color: Theme.alpha(Theme.bgTop, root.fillAlpha) }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.bgMid, root.fillAlpha) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.bgBottom, root.fillAlpha) }
            }
            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
        // Optional tint wash on top of the gradient.
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: root.width
                y2: 0
                GradientStop { position: 0.0; color: Theme.alpha(root.tint, root.tint.a * 0.35) }
                GradientStop { position: 0.6; color: Theme.alpha(root.tint, 0) }
            }
            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }

    // ---- decor, rendered offscreen and masked to the rounded rect
    Item {
        id: decorLayer
        anchors.fill: parent
        visible: false
        layer.enabled: root.decor

        StarField {
            anchors.fill: parent
            count: root.starCount
            seed: root.seed
            nebula: root.nebula
            sparkles: root.sparkles
            twinkle: root.twinkle
            active: root.active
            inset: 4
        }
    }
    Rectangle {
        id: decorMask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: root.decor
    }
    MultiEffect {
        visible: root.decor
        anchors.fill: parent
        source: decorLayer
        maskEnabled: true
        maskSource: decorMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
