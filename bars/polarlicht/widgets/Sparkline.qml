import QtQuick
import qs

// Verlaufsgrafik (nur neu gezeichnet, wenn Daten sich ändern)
Canvas {
    id: root
    property var values: []
    property color stroke: Theme.accent
    property int capacity: 60
    property bool autoScale: true

    onValuesChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const v = values, n = v.length
        if (n < 2) return
        const step = width / (capacity - 1)
        const x0 = width - (n - 1) * step
        const top = autoScale ? Math.max(0.1, Math.max(...v) * 1.25) : 1
        const yOf = y => height - 3 - Math.min(1, y / top) * (height - 6)
        ctx.beginPath()
        ctx.moveTo(x0, yOf(v[0]))
        for (let i = 1; i < n; i++) {
            const xp = x0 + (i - 1) * step, xc = x0 + i * step
            const mx = (xp + xc) / 2
            ctx.bezierCurveTo(mx, yOf(v[i - 1]), mx, yOf(v[i]), xc, yOf(v[i]))
        }
        ctx.lineWidth = 2
        ctx.strokeStyle = stroke
        ctx.stroke()
        ctx.lineTo(width, height); ctx.lineTo(x0, height); ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, Qt.rgba(stroke.r, stroke.g, stroke.b, 0.35))
        g.addColorStop(1, Qt.rgba(stroke.r, stroke.g, stroke.b, 0))
        ctx.fillStyle = g
        ctx.fill()
    }
}
