import QtQuick
import "../../"
import "../../services"

// Thin mirrored bars on the bottom edge: bass in the middle, bell-curve envelope.
// Paints only when cava delivers a frame; hidden (and cava stopped) when silent.
Canvas {
    id: viz

    readonly property int step: Theme.visualizerBarWidth + Theme.visualizerBarGap
    readonly property int count: Math.floor(width / step)
    property var smooth: []
    property real level: 0           // fades the whole thing in/out
    property bool enabled_: true     // off in the menu → hidden, and cava never starts
    property color barColor: Theme.accent
    onBarColorChanged: requestPaint()

    opacity: level
    visible: enabled_ && Cava.installed && level > 0.01
    Binding { target: Cava; property: "wanted"; value: viz.enabled_ }
    renderStrategy: Canvas.Cooperative

    Behavior on level { NumberAnimation { duration: 400; easing.type: Theme.easing } }

    // gaussian envelope across the width, computed once per size
    readonly property var envelope: {
        const out = [];
        const half = count / 2;
        for (let i = 0; i < count; i++) {
            const t = (i + 0.5 - half) / half;
            out.push(Math.exp(-(t * t) / (2 * 0.38 * 0.38)));
        }
        return out;
    }

    Connections {
        target: Cava
        function onValuesChanged() {
            const v = Cava.values;
            const n = viz.count;
            if (v.length === 0) {
                viz.level = 0;
                return;
            }
            const s = viz.smooth.length === n ? viz.smooth : new Array(n).fill(0);
            const half = n / 2;
            let sum = 0;
            for (let i = 0; i < n; i++) {
                // distance from center → cava bar index (low frequencies in the middle)
                const t = Math.abs(i + 0.5 - half) / half;
                const f = t * (v.length - 1);
                const lo = Math.floor(f), hi = Math.min(v.length - 1, lo + 1);
                const val = v[lo] + (v[hi] - v[lo]) * (f - lo);
                s[i] = s[i] * 0.45 + val * viz.envelope[i] * 0.55;
                sum += s[i];
            }
            viz.smooth = s;
            viz.level = sum / n > 0.004 ? 1 : 0;
            viz.requestPaint();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = viz.barColor;
        const w = Theme.visualizerBarWidth;
        const offset = (width - count * step + Theme.visualizerBarGap) / 2;
        for (let i = 0; i < smooth.length; i++) {
            const h = Math.max(0, Math.min(1, smooth[i])) * height;
            if (h < 1) continue;
            const x = offset + i * step;
            const y = height - h;
            // rounded top: half-circle cap on a rectangle
            ctx.beginPath();
            ctx.moveTo(x, height);
            ctx.lineTo(x, y + w / 2);
            ctx.arc(x + w / 2, y + w / 2, w / 2, Math.PI, 0, false);
            ctx.lineTo(x + w, height);
            ctx.closePath();
            ctx.fill();
        }
    }
}
