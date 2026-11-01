import QtQuick

// Small hand-drawn icon set, painted procedurally on a Canvas instead of
// pre-authored vector paths -- every glyph below is just a handful of
// context2d calls on a 24x24 grid, scaled to whatever size is requested.
Canvas {
    id: root

    property string name: "dot"
    property color tint: "white"
    property real weight: 1.8
    property bool fill: false

    width: 16
    height: 16
    antialiasing: true

    onNameChanged: requestPaint()
    onTintChanged: requestPaint()
    onWeightChanged: requestPaint()
    onFillChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    function _s(ctx) {
        ctx.scale(root.width / 24, root.height / 24);
        ctx.lineWidth = root.weight;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.strokeStyle = root.tint;
        ctx.fillStyle = root.tint;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, root.width, root.height);
        ctx.save();
        _s(ctx);

        switch (root.name) {
        case "search":
            ctx.beginPath(); ctx.arc(10, 10, 6.4, 0, Math.PI * 2); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(14.6, 14.6); ctx.lineTo(20.5, 20.5); ctx.stroke();
            break;
        case "image":
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(3.5, 4.5, 17, 15, 2.5) : ctx.rect(3.5, 4.5, 17, 15); ctx.stroke();
            ctx.beginPath(); ctx.arc(9, 10.5, 1.6, 0, Math.PI * 2); ctx.fill();
            ctx.beginPath();
            ctx.moveTo(4.5, 17.5); ctx.lineTo(9.5, 12); ctx.lineTo(13, 15.5); ctx.lineTo(16.5, 11.5); ctx.lineTo(19.5, 15.5);
            ctx.stroke();
            break;
        case "gear":
            ctx.beginPath(); ctx.arc(12, 12, 3.6, 0, Math.PI * 2); ctx.stroke();
            for (let i = 0; i < 8; i++) {
                const a = (Math.PI / 4) * i;
                const x1 = 12 + Math.cos(a) * 7.2, y1 = 12 + Math.sin(a) * 7.2;
                const x2 = 12 + Math.cos(a) * 9.6, y2 = 12 + Math.sin(a) * 9.6;
                ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
            }
            break;
        case "bell":
            ctx.beginPath();
            ctx.moveTo(7, 15.5);
            ctx.bezierCurveTo(7, 11, 7.5, 5.5, 12, 5.5);
            ctx.bezierCurveTo(16.5, 5.5, 17, 11, 17, 15.5);
            ctx.lineTo(19, 17.5); ctx.lineTo(5, 17.5); ctx.closePath();
            ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 20, 1.7, 0, Math.PI); ctx.stroke();
            break;
        case "power":
            ctx.beginPath(); ctx.arc(12, 13, 6.5, Math.PI * 0.2, Math.PI * 1.8, false); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(12, 4.5); ctx.lineTo(12, 12.5); ctx.stroke();
            break;
        case "lock":
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(5.5, 11, 13, 9.5, 2) : ctx.rect(5.5, 11, 13, 9.5); ctx.stroke();
            ctx.beginPath(); ctx.arc(12, 9, 4, Math.PI, 0, false); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(12, 14.5); ctx.lineTo(12, 17); ctx.stroke();
            break;
        case "refresh":
            ctx.beginPath(); ctx.arc(12, 12, 7, -Math.PI * 0.15, Math.PI * 1.3, false); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(17.6, 4.5); ctx.lineTo(19, 8.2); ctx.lineTo(15.2, 7.2); ctx.closePath(); ctx.fill();
            break;
        case "logout":
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(4.5, 5, 8, 14, 2) : ctx.rect(4.5, 5, 8, 14); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(11, 12); ctx.lineTo(20, 12); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(16.5, 8); ctx.lineTo(20.3, 12); ctx.lineTo(16.5, 16); ctx.stroke();
            break;
        case "sun":
            ctx.beginPath(); ctx.arc(12, 12, 4, 0, Math.PI * 2); ctx.stroke();
            for (let i = 0; i < 8; i++) {
                const a = (Math.PI / 4) * i;
                const x1 = 12 + Math.cos(a) * 7.5, y1 = 12 + Math.sin(a) * 7.5;
                const x2 = 12 + Math.cos(a) * 10, y2 = 12 + Math.sin(a) * 10;
                ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
            }
            break;
        case "moon":
            ctx.beginPath();
            ctx.arc(13, 12, 8, Math.PI * 0.6, Math.PI * 1.85, false);
            ctx.arc(9.5, 9, 6, Math.PI * 1.85 - Math.PI, Math.PI * 0.6 - Math.PI, true);
            ctx.closePath();
            ctx.fill();
            break;
        case "drop":
            ctx.beginPath();
            ctx.moveTo(12, 3.5);
            ctx.bezierCurveTo(8, 9.5, 5.5, 13, 5.5, 16);
            ctx.bezierCurveTo(5.5, 19.6, 8.4, 21.5, 12, 21.5);
            ctx.bezierCurveTo(15.6, 21.5, 18.5, 19.6, 18.5, 16);
            ctx.bezierCurveTo(18.5, 13, 16, 9.5, 12, 3.5);
            ctx.closePath();
            ctx.fill();
            break;
        case "check":
            ctx.beginPath(); ctx.moveTo(4.5, 12.5); ctx.lineTo(9.5, 17.5); ctx.lineTo(19.5, 6); ctx.stroke();
            break;
        case "close":
            ctx.beginPath(); ctx.moveTo(6, 6); ctx.lineTo(18, 18); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(18, 6); ctx.lineTo(6, 18); ctx.stroke();
            break;
        case "volume":
            ctx.beginPath();
            ctx.moveTo(4, 9.5); ctx.lineTo(8, 9.5); ctx.lineTo(13, 5); ctx.lineTo(13, 19); ctx.lineTo(8, 14.5); ctx.lineTo(4, 14.5);
            ctx.closePath(); ctx.fill();
            ctx.beginPath(); ctx.arc(16.5, 12, 4, -Math.PI * 0.32, Math.PI * 0.32, false); ctx.stroke();
            break;
        case "cpu":
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(7, 7, 10, 10, 1.5) : ctx.rect(7, 7, 10, 10); ctx.stroke();
            for (let i = 0; i < 3; i++) {
                const p = 9 + i * 3;
                ctx.beginPath(); ctx.moveTo(p, 3.5); ctx.lineTo(p, 7); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(p, 17); ctx.lineTo(p, 20.5); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(3.5, p); ctx.lineTo(7, p); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(17, p); ctx.lineTo(20.5, p); ctx.stroke();
            }
            break;
        default: // "grid" fallback
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(4, 4, 7, 7, 1.5) : ctx.rect(4, 4, 7, 7); ctx.stroke();
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(13, 4, 7, 7, 1.5) : ctx.rect(13, 4, 7, 7); ctx.stroke();
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(4, 13, 7, 7, 1.5) : ctx.rect(4, 13, 7, 7); ctx.stroke();
            ctx.beginPath(); ctx.roundRect ? ctx.roundRect(13, 13, 7, 7, 1.5) : ctx.rect(13, 13, 7, 7); ctx.stroke();
        }

        ctx.restore();
    }
}
