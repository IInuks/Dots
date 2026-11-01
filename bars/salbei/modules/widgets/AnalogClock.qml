import QtQuick
import "../../"

// Analog clock face for the desktop layer: hour + minute hands in the ink
// color, optional second hand + center dot in the accent. Colors come from
// the DeskWidget (ink follows the wallpaper). The menu's preview
// (menu/steps/WidgetsStep.qml, analogC) paints the same face -- keep in sync.
Canvas {
    id: face

    property date time: new Date()
    property real size: 180
    property bool seconds: true
    property bool numbers: false
    property bool ticks: true
    property color ink: Theme.text
    property color inkDim: Theme.textDim
    property color inkFaint: Theme.textFaint
    property color accent: Theme.accent

    width: size
    height: size
    renderStrategy: Canvas.Cooperative

    onTimeChanged: requestPaint()
    onSizeChanged: requestPaint()
    onSecondsChanged: requestPaint()
    onNumbersChanged: requestPaint()
    onTicksChanged: requestPaint()
    onInkChanged: requestPaint()
    onInkDimChanged: requestPaint()
    onInkFaintChanged: requestPaint()
    onAccentChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const s = size, r = s / 2;
        ctx.translate(r, r);
        ctx.lineCap = "round";

        // rim
        ctx.strokeStyle = inkFaint;
        ctx.lineWidth = Math.max(1.5, s * 0.012);
        ctx.beginPath();
        ctx.arc(0, 0, r - ctx.lineWidth / 2, 0, 2 * Math.PI);
        ctx.stroke();

        // hour + minute ticks (the hour ticks under the numbers make room)
        for (let i = 0; i < 60; i++) {
            const hour = i % 5 === 0;
            if (!hour && !ticks) continue;
            if (numbers && i % 15 === 0) continue;
            const a = i * Math.PI / 30;
            const len = hour ? s * 0.07 : s * 0.03;
            const out = r - s * 0.045;
            ctx.strokeStyle = hour ? inkDim : inkFaint;
            ctx.lineWidth = hour ? Math.max(2, s * 0.022) : Math.max(1, s * 0.008);
            ctx.beginPath();
            ctx.moveTo(Math.sin(a) * out, -Math.cos(a) * out);
            ctx.lineTo(Math.sin(a) * (out - len), -Math.cos(a) * (out - len));
            ctx.stroke();
        }

        if (numbers) {
            ctx.fillStyle = ink;
            ctx.font = "600 " + Math.round(s * 0.13) + "px \"" + Theme.fontFamily + "\"";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            const nr = r - s * 0.13;
            [12, 3, 6, 9].forEach((n, k) => {
                const a = k * Math.PI / 2;
                ctx.fillText(String(n), Math.sin(a) * nr, -Math.cos(a) * nr);
            });
        }

        const h = time.getHours() % 12, m = time.getMinutes(), sec = time.getSeconds();
        function hand(angle, len, tail, width, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = width;
            ctx.beginPath();
            ctx.moveTo(-Math.sin(angle) * tail, Math.cos(angle) * tail);
            ctx.lineTo(Math.sin(angle) * len, -Math.cos(angle) * len);
            ctx.stroke();
        }
        hand((h + m / 60) * Math.PI / 6, r * 0.5, r * 0.08, Math.max(3, s * 0.04), ink);
        hand((m + (seconds ? sec / 60 : 0)) * Math.PI / 30, r * 0.74, r * 0.08, Math.max(2, s * 0.028), ink);
        if (seconds)
            hand(sec * Math.PI / 30, r * 0.8, r * 0.16, Math.max(1, s * 0.01), accent);

        ctx.fillStyle = accent;
        ctx.beginPath();
        ctx.arc(0, 0, Math.max(3, s * 0.03), 0, 2 * Math.PI);
        ctx.fill();
    }
}
