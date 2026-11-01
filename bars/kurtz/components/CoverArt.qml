import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../"

// Album art clipped to a circle (or rounded square), with an optional
// dotted "orbit" ring spinning around it while `spinning`. Falls back to a
// purple media orb with a note glyph when there is no art.
Item {
    id: root
    property string source: ""
    property bool round: true
    property bool orbit: false
    property bool spinning: false
    property real orbitGap: 4

    readonly property bool hasArt: img.status === Image.Ready

    implicitWidth: 28
    implicitHeight: 28

    // fallback orb
    Orb {
        anchors.fill: parent
        visible: !root.hasArt
        color: Theme.media
        crescent: 0.18
        KIcon {
            anchors.centerIn: parent
            text: Glyphs.music
            size: parent.width * 0.45
            color: Theme.shadeOf(Theme.shadeOf(Theme.media))
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 256
        sourceSize.height: 256
        layer.enabled: true
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.round ? width / 2 : Theme.rMed
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: root.hasArt
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    // shadow crescent over the art, so even photos obey the light rule
    Rectangle {
        visible: root.hasArt && root.round
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.shadowColor, 0.35) }
        }
    }

    // dotted orbit ring
    Shape {
        id: ring
        visible: root.orbit
        anchors.centerIn: parent
        width: root.width + root.orbitGap * 2
        height: width
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.alpha(Theme.media, 0.9)
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine
            dashPattern: [0.01, 3.2]
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.width / 2 - 1
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
        // one bright "moon" riding the orbit
        Rectangle {
            width: 5
            height: 5
            radius: 2.5
            color: Theme.magenta
            x: ring.width - width
            y: ring.height / 2 - 2.5
        }
        RotationAnimation on rotation {
            running: root.orbit && root.spinning && Theme.animations
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
        }
    }
}
