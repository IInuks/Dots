import QtQuick
import "Liquid.js" as L

// Ein Tropfen (Spitze oben). Mit `level` >= 0 ist er ein Pegel: bis zur
// Höhe level mit `fill` gefüllt, darüber `empty`, die Grenze leicht
// gewellt. Ohne level einfach massiv in `fill`. Malt nur bei Änderungen.
Canvas {
    id: c
    property real level: -1
    property color fill: Theme.accent
    property color empty: Theme.surface3
    property color rim: "transparent"
    property bool shine: true
    property real phase: 0          // Wellen-Phase der Pegellinie

    implicitWidth: 14
    implicitHeight: 19

    // Pegel gleitet, statt zu springen
    property real _lv: level
    Behavior on _lv { enabled: Theme.motion; NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutCubic } }

    readonly property var deps: [width, height, _lv, fill, empty, rim, shine, phase]
    onDepsChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width / 2, height / 2.6) - 0.6;
        const cx = width / 2, cy = height - r - 0.6;
        const tip = cy - 0.6;
        ctx.beginPath();
        L.drop(ctx, cx, cy, r, tip);
        if (c._lv < 0) {
            ctx.fillStyle = c.fill;
            ctx.fill();
        } else {
            ctx.fillStyle = c.empty;
            ctx.fill();
            ctx.save();
            ctx.beginPath();
            L.drop(ctx, cx, cy, r, tip);
            ctx.clip();
            const top = 0.6, bottom = cy + r;
            const y = bottom - (bottom - top) * Math.max(0, Math.min(1, c._lv));
            ctx.fillStyle = c.fill;
            ctx.beginPath();
            L.wave(ctx, width, y, Math.min(1.4, r * 0.12), width * 0.9, c.phase, height + 2);
            ctx.fill();
            ctx.restore();
        }
        if (c.rim.a > 0) {
            ctx.strokeStyle = c.rim;
            ctx.lineWidth = 1.2;
            ctx.beginPath();
            L.drop(ctx, cx, cy, r - 0.3, tip);
            ctx.stroke();
        }
        if (c.shine) {
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.22);
            ctx.beginPath();
            ctx.ellipse(cx - r * 0.68, cy - r * 0.55, r * 0.22, r * 0.38);   // x, y = linke obere Ecke
            ctx.fill();
        }
    }
}
