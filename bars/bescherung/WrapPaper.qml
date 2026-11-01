import QtQuick

// Ein Stueck Geschenkpapier. Zeichnet einen Ausschnitt [offsetX, offsetX+width)
// aus einem Bogen der Breite fullWidth, damit zwei Haelften zusammen exakt
// ein Papier ergeben. Wird nur bei Groessenaenderung neu gezeichnet.
Canvas {
    id: root

    property int paper: 0
    property real fullWidth: width
    property real offsetX: 0
    property real radius: 8
    readonly property var look: Theme.paper(paper)

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFullWidthChanged: requestPaint()
    onOffsetXChanged: requestPaint()
    onPaperChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const W = fullWidth, H = height;
        ctx.reset();
        ctx.save();
        ctx.translate(-offsetX, 0);
        ctx.beginPath();
        ctx.roundedRect(0, 0, W, H, radius, radius);
        ctx.clip();
        ctx.fillStyle = look.paper;
        ctx.fillRect(0, 0, W, H);
        ctx.fillStyle = look.stripe;
        ctx.strokeStyle = look.stripe;
        ctx.lineCap = "round";

        switch (look.pattern) {
        case "stripes":
            ctx.lineWidth = 3.5;
            for (let x = -H; x < W + H; x += 10) {
                ctx.beginPath();
                ctx.moveTo(x, H);
                ctx.lineTo(x + H, 0);
                ctx.stroke();
            }
            break;
        case "dots":
            for (let y = 4, row = 0; y < H + 4; y += 8, row++)
                for (let x = (row % 2) * 5 + 3; x < W + 4; x += 10) {
                    ctx.beginPath();
                    ctx.arc(x, y, 1.9, 0, Math.PI * 2);
                    ctx.fill();
                }
            break;
        case "zigzag":
            ctx.lineWidth = 2.2;
            for (let y = 5; y < H + 6; y += 9) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                for (let x = 0; x < W + 6; x += 6)
                    ctx.lineTo(x + 3, (x / 6) % 2 === 0 ? y - 3 : y + 1);
                ctx.stroke();
            }
            break;
        case "stars":
            ctx.lineWidth = 1.6;
            for (let y = 5, row = 0; y < H + 6; y += 11, row++)
                for (let x = (row % 2) * 7 + 4; x < W + 6; x += 14) {
                    ctx.beginPath();
                    ctx.moveTo(x - 3, y); ctx.lineTo(x + 3, y);
                    ctx.moveTo(x, y - 3); ctx.lineTo(x, y + 3);
                    ctx.moveTo(x - 1.8, y - 1.8); ctx.lineTo(x + 1.8, y + 1.8);
                    ctx.moveTo(x - 1.8, y + 1.8); ctx.lineTo(x + 1.8, y - 1.8);
                    ctx.stroke();
                }
            break;
        case "checks":
            ctx.globalAlpha = 0.55;
            for (let y = 0, row = 0; y < H; y += 7, row++)
                for (let x = (row % 2) * 7; x < W; x += 14)
                    ctx.fillRect(x, y, 7, 7);
            ctx.globalAlpha = 1;
            break;
        case "waves":
            ctx.lineWidth = 2.2;
            for (let y = 4; y < H + 6; y += 8) {
                ctx.beginPath();
                for (let x = 0; x <= W + 8; x += 8)
                    ctx.arc(x + 4, y, 4, Math.PI, 0, false);
                ctx.stroke();
            }
            break;
        }
        ctx.restore();
    }
}
