import QtQuick

// Small filled sparkline for a rolling 0..maxValue history (CPU/RAM/GPU).
Item {
    id: chart

    property var history: []
    property color color: Theme.accent
    property real maxValue: 100

    implicitHeight: 40

    onHistoryChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height;
            ctx.clearRect(0, 0, w, h);

            const data = chart.history;
            if (!data || data.length < 2) return;

            ctx.strokeStyle = Qt.alpha(chart.color, 0.12);
            ctx.lineWidth = 1;
            for (const frac of [0.33, 0.66]) {
                const y = h * (1 - frac);
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(w, y);
                ctx.stroke();
            }

            const stepX = w / (data.length - 1);
            const px = i => i * stepX;
            const py = v => h - (Math.max(0, Math.min(chart.maxValue, v)) / chart.maxValue) * h;

            const grad = ctx.createLinearGradient(0, 0, 0, h);
            grad.addColorStop(0, Qt.alpha(chart.color, 0.4));
            grad.addColorStop(1, Qt.alpha(chart.color, 0.02));

            ctx.beginPath();
            ctx.moveTo(px(0), py(data[0]));
            for (let i = 1; i < data.length; i++) ctx.lineTo(px(i), py(data[i]));
            ctx.lineTo(px(data.length - 1), h);
            ctx.lineTo(px(0), h);
            ctx.closePath();
            ctx.fillStyle = grad;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(px(0), py(data[0]));
            for (let i = 1; i < data.length; i++) ctx.lineTo(px(i), py(data[i]));
            ctx.strokeStyle = chart.color;
            ctx.lineWidth = 1.8;
            ctx.lineJoin = "round";
            ctx.stroke();
        }
    }
}
