import QtQuick

// Verlaufskurve (Sparkline) mit gefüllter Fläche.
Canvas {
    id: k
    property var values: []
    property color tint: Theme.accent
    onValuesChanged: requestPaint()
    onTintChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = values, n = v.length;
        if (n < 2) return;
        const step = width / (Stats.histLen - 1), off = width - (n - 1) * step;
        const top = Math.max(0.25, Math.max.apply(null, v) * 1.15);   // Kurve füllt die Höhe
        const y = i => height - 2 - Math.min(1, v[i] / top) * (height - 4);
        ctx.beginPath();
        ctx.moveTo(off, y(0));
        for (let i = 1; i < n; i++) {
            const x0 = off + (i - 1) * step, x1 = off + i * step;
            ctx.bezierCurveTo(x0 + step / 2, y(i - 1), x1 - step / 2, y(i), x1, y(i));
        }
        ctx.lineWidth = 2; ctx.strokeStyle = tint; ctx.stroke();
        ctx.lineTo(width, height); ctx.lineTo(off, height); ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(tint.r, tint.g, tint.b, 0.35));
        g.addColorStop(1, Qt.rgba(tint.r, tint.g, tint.b, 0));
        ctx.fillStyle = g; ctx.fill();
    }
}
