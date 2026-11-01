import QtQuick
import "../.."

// The LCD panel look shared by the bar background and every module/menu
// surface: base fill, a very faint pixel grid, and a diagonal glass glint.
// Both the grid and the glint are fully static per size/theme -- they never
// animate on their own -- so the grid is a Canvas rendered once and cached
// (layer.enabled) rather than redrawn every frame, and the glint is a plain
// rotated gradient Rectangle rather than anything procedural.
Item {
    id: root

    property color base: Theme.surface
    property real gridOpacity: 0.05

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.base
    }

    Canvas {
        id: grid
        anchors.fill: parent
        opacity: root.gridOpacity
        layer.enabled: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "white";
            ctx.lineWidth = 1;
            const step = 3;
            ctx.beginPath();
            for (let x = 0.5; x < width; x += step) {
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
            }
            for (let y = 0.5; y < height; y += step) {
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            ctx.stroke();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    Rectangle {
        width: parent.width * 1.6
        height: parent.height * 0.9
        x: -parent.width * 0.3
        y: -parent.height * 0.05
        rotation: -18
        antialiasing: true
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: Theme.glassTint
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }

    // Etappe 9 idle glint: a narrower, brighter highlight than the static
    // glass glint above, sweeping left-to-right every Theme.idleGlintInterval
    // -- light catching the glass at rest, distinct from the always-on
    // texture element built in Etappe 1. Rests fully off-surface (x starts
    // at -width) between sweeps, so it costs nothing to look at while idle.
    Rectangle {
        id: idleGlint
        width: parent.width * 0.35
        height: parent.height * 1.4
        x: -width
        y: -parent.height * 0.2
        rotation: -18
        antialiasing: true
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: Theme.glassTint
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }

        SequentialAnimation {
            loops: Animation.Infinite
            running: !Theme.reducedMotion
            PauseAnimation {
                duration: Theme.idleGlintInterval
            }
            NumberAnimation {
                target: idleGlint
                property: "x"
                from: -idleGlint.width
                to: root.width + idleGlint.width
                duration: Theme.durIdle
                easing.type: Theme.easeInOut
            }
        }
    }
}
