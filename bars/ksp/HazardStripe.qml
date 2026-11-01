import QtQuick

// Diagonal caution-stripe strip (the orange/black hazard tape look on
// KSP's VAB/SPH gantry doors and warning panels). Redraws on resize and
// whenever the accent color changes.
Canvas {
    id: root
    property color stripeColor: Theme.accent
    property color gapColor: "#0a0c10"
    property real stripeWidth: 7

    onStripeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.gapColor;
        ctx.fillRect(0, 0, width, height);
        ctx.fillStyle = root.stripeColor;
        const step = root.stripeWidth * 2;
        const diag = height; // 45-degree stripes
        for (let x = -diag; x < width + diag; x += step) {
            ctx.beginPath();
            ctx.moveTo(x, height);
            ctx.lineTo(x + diag, 0);
            ctx.lineTo(x + diag + root.stripeWidth, 0);
            ctx.lineTo(x + root.stripeWidth, height);
            ctx.closePath();
            ctx.fill();
        }
    }
}
