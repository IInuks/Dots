import QtQuick

// Retro CRT screen texture: repeating horizontal scanlines + a radial
// vignette, drawn once into a Canvas and only repainted on resize/tuning
// change (not per-frame -- this is a static texture, not a shader). An
// occasional brief dim/brighten pulse on top sells "the tube is alive"
// without being distracting. Meant to sit as the topmost child inside a
// clipped panel/bar background, above text and everything else, exactly
// like scanlines sit on top of the picture on a real CRT.
Canvas {
    id: root
    property real scanlineOpacity: Theme.crtScanlineOpacity
    property real vignetteStrength: Theme.crtVignette
    property bool flicker: Theme.crtFlicker

    onScanlineOpacityChanged: requestPaint()
    onVignetteStrengthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (root.scanlineOpacity > 0) {
            ctx.fillStyle = Qt.rgba(0, 0, 0, root.scanlineOpacity);
            for (let y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1);
        }
        if (root.vignetteStrength > 0) {
            const cx = width / 2, cy = height / 2;
            const r = Math.sqrt(cx * cx + cy * cy);
            const grad = ctx.createRadialGradient(cx, cy, r * 0.55, cx, cy, r);
            grad.addColorStop(0, "rgba(0,0,0,0)");
            grad.addColorStop(1, Qt.rgba(0, 0, 0, root.vignetteStrength));
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, width, height);
        }
    }

    opacity: 1
    SequentialAnimation on opacity {
        running: root.flicker
        loops: Animation.Infinite
        PauseAnimation { duration: 5200 }
        NumberAnimation { to: 0.78; duration: 55 }
        NumberAnimation { to: 1.0; duration: 85 }
        PauseAnimation { duration: 3400 }
        NumberAnimation { to: 0.85; duration: 40 }
        NumberAnimation { to: 1.0; duration: 70 }
    }
}
