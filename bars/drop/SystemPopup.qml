import QtQuick
import "Liquid.js" as L

// System als Pegelstand: CPU und RAM sind große Tropfen, die bis zur
// Auslastung gefüllt sind (die Oberfläche schwappt bei jeder Messung),
// darunter der Pegelverlauf der letzten Minute und ein Röhrchen pro Kern.
Drip {
    id: root
    popupId: "system"
    cardWidth: 380

    // Schwappen: bei jeder neuen Messung kurz die Wellen-Phase verschieben
    property real slosh: 0
    Connections {
        target: Stats
        function onCpuHistChanged() { if (root.shown && Theme.motion) sloshAnim.restart(); }
    }
    NumberAnimation { id: sloshAnim; target: root; property: "slosh"; from: root.slosh; to: root.slosh + Math.PI; duration: Theme.ms(800); easing.type: Easing.OutQuad }

    Column {
        width: parent.width
        spacing: 14

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 34
            Repeater {
                model: 2
                Column {
                    id: gauge
                    required property int index
                    readonly property bool cpu: index === 0
                    readonly property real v: cpu ? Stats.cpu : Stats.mem
                    readonly property color tint: cpu ? Theme.accent : Theme.accent2
                    spacing: 4
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 78; height: 104
                        Droplet {
                            anchors.fill: parent
                            level: gauge.v
                            fill: gauge.tint
                            empty: Theme.surface2
                            rim: Theme.alpha(gauge.tint, 0.45)
                            phase: root.slosh
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height - 52
                            text: Math.round(gauge.v * 100)
                            rounded: true; bold: true; size: 22
                            color: gauge.v > 0.45 ? Theme.accentInk : Theme.text
                        }
                    }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: gauge.cpu ? "CPU" : "RAM"; bold: true; size: 12 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: gauge.cpu ? (Stats.temp > 0 ? Math.round(Stats.temp) + " °C" : "") : Stats.memUsed.toFixed(1) + " / " + Stats.memTotal.toFixed(0) + " GiB"; size: 11; color: Theme.textDim }
                }
            }
        }

        Heading { text: "Pegelverlauf · 60 s" }
        Canvas {
            id: hist
            width: parent.width; height: 70
            readonly property var deps: [Stats.cpuHist, Stats.memHist, Theme.accent, Theme.accent2]
            onDepsChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height, n = Stats.histLen;
                const draw = (arr, col, a) => {
                    if (arr.length < 2) return;
                    const step = w / (n - 1), off = (n - arr.length) * step;
                    ctx.beginPath();
                    ctx.moveTo(off, h);
                    for (let i = 0; i < arr.length; i++) {
                        const x = off + i * step, y = h - 2 - arr[i] * (h - 6);
                        if (i === 0) ctx.lineTo(x, y);
                        else {
                            const px = off + (i - 1) * step, py = h - 2 - arr[i - 1] * (h - 6);
                            ctx.bezierCurveTo((px + x) / 2, py, (px + x) / 2, y, x, y);
                        }
                    }
                    ctx.lineTo(w, h);
                    ctx.closePath();
                    const g = ctx.createLinearGradient(0, 0, 0, h);
                    g.addColorStop(0, Theme.alpha(col, a));
                    g.addColorStop(1, Theme.alpha(col, 0.02));
                    ctx.fillStyle = g;
                    ctx.fill();
                };
                draw(Stats.memHist, Theme.accent2, 0.35);
                draw(Stats.cpuHist, Theme.accent, 0.55);
            }
            Rectangle { anchors.fill: parent; color: "transparent"; radius: 10; border.width: 1; border.color: Theme.line }
        }

        Heading { text: "Kerne"; visible: Stats.cores.length > 0 }
        Row {
            width: parent.width
            spacing: 3
            visible: Stats.cores.length > 0
            Repeater {
                model: Stats.cores
                Rectangle {
                    required property real modelData
                    width: (parent.width - (Stats.cores.length - 1) * 3) / Math.max(1, Stats.cores.length)
                    height: 34; radius: Math.min(width / 2, 5)
                    color: Theme.surface2
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(parent.radius * 2, parent.height * parent.modelData)
                        radius: parent.radius
                        color: Theme.mix(Theme.accent, Theme.accent2, parent.modelData)
                        Behavior on height { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        Row {
            spacing: 18
            Label { text: "läuft seit " + Stats.uptime; size: 12; color: Theme.textDim }
            Label { text: "Last " + Stats.load.map(x => x.toFixed(2)).join("  "); size: 12; color: Theme.textDim; font.family: Theme.mono }
        }
    }
}
