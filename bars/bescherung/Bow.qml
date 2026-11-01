import QtQuick

// Die Schleife oben auf jedem Geschenk: zwei Schlaufen, ein Knoten, zwei
// Baender. Statisch gezeichnet; bewegt wird sie von aussen.
Canvas {
    id: root

    property color ribbon: "#ffd166"
    width: 32
    height: 18

    onRibbonChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const cx = width / 2, cy = 11;
        const edge = Qt.darker(ribbon, 1.35);
        ctx.reset();
        ctx.lineJoin = "round";
        ctx.lineWidth = 1.2;
        ctx.strokeStyle = edge;
        ctx.fillStyle = ribbon;

        // Baender
        ctx.beginPath();
        ctx.moveTo(cx - 1, cy);
        ctx.lineTo(cx - 7, cy + 7);
        ctx.lineTo(cx - 4, cy + 6);
        ctx.lineTo(cx - 3, cy + 8);
        ctx.closePath();
        ctx.moveTo(cx + 1, cy);
        ctx.lineTo(cx + 7, cy + 7);
        ctx.lineTo(cx + 4, cy + 6);
        ctx.lineTo(cx + 3, cy + 8);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        // Schlaufen
        for (const s of [-1, 1]) {
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.bezierCurveTo(cx + s * 4, cy - 12, cx + s * 16, cy - 10, cx + s * 14, cy - 1);
            ctx.bezierCurveTo(cx + s * 13, cy + 4, cx + s * 5, cy + 2, cx, cy);
            ctx.fill();
            ctx.stroke();
            // Innenschatten der Schlaufe
            ctx.beginPath();
            ctx.moveTo(cx + s * 3, cy - 1);
            ctx.quadraticCurveTo(cx + s * 9, cy - 6, cx + s * 11, cy - 1);
            ctx.stroke();
        }

        // Knoten
        ctx.beginPath();
        ctx.ellipse(cx - 3.2, cy - 3, 6.4, 6);
        ctx.fill();
        ctx.stroke();
    }
}
