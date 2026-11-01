import QtQuick

// Ein Ei, auf Canvas gemalt. Optional mit Folien-Band (das gezackte Band
// der Überraschungsei-Folie), Glanzlicht und Rissen. Wird nur neu gemalt,
// wenn sich eine Eigenschaft ändert -- kostet im Leerlauf nichts.
Canvas {
    id: egg
    property color fill: Theme.text
    property color band: "transparent"
    property color outline: "transparent"
    property real outlineWidth: 1.5
    property bool shine: true
    property real crack: 0          // 0..1, zeichnet einen Zickzack-Riss
    property int half: 0            // 0 = ganz, 1 = nur obere Hälfte, 2 = nur untere

    onFillChanged: requestPaint()
    onBandChanged: requestPaint()
    onOutlineChanged: requestPaint()
    onCrackChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function eggPath(ctx, w, h, o) {
        ctx.beginPath();
        ctx.moveTo(w / 2, o);
        ctx.bezierCurveTo(w * 0.86, o, w - o, h * 0.36, w - o, h * 0.62);
        ctx.bezierCurveTo(w - o, h * 0.87, w * 0.78, h - o, w / 2, h - o);
        ctx.bezierCurveTo(w * 0.22, h - o, o, h * 0.87, o, h * 0.62);
        ctx.bezierCurveTo(o, h * 0.36, w * 0.14, o, w / 2, o);
        ctx.closePath();
    }
    // Zickzacklinie über die Breite auf Höhe y
    function zig(ctx, w, y, amp, n) {
        for (let i = 0; i <= n; i++)
            ctx.lineTo(w * i / n, y + (i % 2 ? amp : -amp));
    }

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height, o = outline.a > 0 ? outlineWidth / 2 + 0.5 : 0.5;
        ctx.reset();
        if (w <= 0 || h <= 0) return;
        ctx.save();
        eggPath(ctx, w, h, o);
        ctx.clip();

        // Hälfte ausschneiden (für das aufgebrochene Ei)
        if (half !== 0) {
            ctx.beginPath();
            const y = h * 0.55, amp = h * 0.05;
            if (half === 1) { ctx.moveTo(0, 0); ctx.lineTo(0, y); zig(ctx, w, y, amp, 8); ctx.lineTo(w, 0); }
            else { ctx.moveTo(0, h); ctx.lineTo(0, y); zig(ctx, w, y, amp, 8); ctx.lineTo(w, h); }
            ctx.closePath();
            ctx.clip();
        }

        ctx.fillStyle = fill;
        ctx.fillRect(0, 0, w, h);

        if (band.a > 0) {
            ctx.fillStyle = band;
            ctx.beginPath();
            ctx.moveTo(0, h * 0.44);
            zig(ctx, w, h * 0.44, h * 0.035, 10);
            ctx.lineTo(w, h * 0.66);
            for (let i = 10; i >= 0; i--)
                ctx.lineTo(w * i / 10, h * 0.66 + (i % 2 ? h * 0.035 : -h * 0.035));
            ctx.closePath();
            ctx.fill();
        }
        if (shine) {
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.28);
            ctx.beginPath();
            ctx.ellipse(w * 0.22, h * 0.16, w * 0.2, h * 0.26);
            ctx.fill();
        }
        ctx.restore();

        if (crack > 0) {
            ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.55);
            ctx.lineWidth = Math.max(1, w / 30);
            ctx.lineJoin = "round";
            ctx.beginPath();
            const n = 8, y = h * 0.55, amp = h * 0.05, last = Math.ceil(n * crack);
            ctx.moveTo(0, y);
            for (let i = 1; i <= last; i++)
                ctx.lineTo(w * Math.min(i / n, crack), y + (i % 2 ? amp : -amp));
            ctx.stroke();
        }
        if (outline.a > 0) {
            ctx.strokeStyle = outline;
            ctx.lineWidth = outlineWidth;
            eggPath(ctx, w, h, o);
            ctx.stroke();
        }
    }
}
