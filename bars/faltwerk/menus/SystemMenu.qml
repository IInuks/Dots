import QtQuick
import "../core"
import "../fold"

// Messwerk: faltet sich seitlich als Leporello (4 Streifen) auf. Jeder Wert
// ist ein Papierstreifen, in den ein farbiger Streifen geschoben wird; oben
// eine Bleistiftskizze der CPU-Last der letzten zwei Minuten.
Menu {
    id: m
    menuId: "system"
    width: 360
    height: 384

    Fold {
        width: m.width + 6
        height: m.height + 6
        segments: 4
        vertical: false
        progress: m.progress

        Sheet {
            anchors.fill: parent
            anchors.rightMargin: 6
            anchors.bottomMargin: 6

            Column {
                x: 22
                y: 18
                width: parent.width - 44
                spacing: 12

                Row {
                    spacing: 8
                    Text {
                        text: "Messwerk"
                        font.family: Paper.serif
                        font.pixelSize: 20
                        font.bold: true
                        color: Paper.ink
                    }
                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: "läuft seit " + Sys.uptimeText()
                        font.family: Paper.serif
                        font.italic: true
                        font.pixelSize: 12
                        color: Paper.soft
                    }
                }

                // Skizze
                Item {
                    width: parent.width
                    height: 70
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Paper.deep
                        radius: 3
                    }
                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            required property int index
                            y: (index + 1) * parent.height / 4
                            width: parent.width
                            height: 1
                            color: Paper.deep
                            opacity: 0.6
                        }
                    }
                    Canvas {
                        id: spark
                        anchors.fill: parent
                        anchors.margins: 3
                        property var data: Sys.cpuHistory
                        property color ink: Paper.accent
                        onDataChanged: if (m.shown) requestPaint()
                        onInkChanged: requestPaint()
                        Connections {
                            target: m
                            function onShownChanged() { if (m.shown) spark.requestPaint(); }
                        }
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const d = data;
                            if (d.length < 2)
                                return;
                            const step = width / 39;
                            const x0 = width - (d.length - 1) * step;
                            ctx.beginPath();
                            for (let i = 0; i < d.length; i++) {
                                // leichtes Zittern = Bleistift
                                const jit = ((i * 7919) % 5 - 2) * 0.35;
                                const x = x0 + i * step, y = height - d[i] * (height - 4) - 2 + jit;
                                if (i === 0)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }
                            ctx.strokeStyle = ink;
                            ctx.lineWidth = 1.8;
                            ctx.lineJoin = "round";
                            ctx.stroke();
                            ctx.lineTo(width, height);
                            ctx.lineTo(x0, height);
                            ctx.closePath();
                            ctx.globalAlpha = 0.12;
                            ctx.fillStyle = ink;
                            ctx.fill();
                        }
                    }
                }

                Repeater {
                    model: [
                        { label: "Prozessor", v: Sys.cpu, text: Math.round(Sys.cpu * 100) + " %", c: Paper.accent },
                        { label: "Speicher", v: Sys.mem, text: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " GB", c: Paper.second },
                        { label: "Platte /", v: Sys.disk, text: Sys.diskText, c: Paper.ink },
                        { label: "Temperatur", v: Math.min(1, Sys.temp / 95), text: Sys.temp.toFixed(0) + " °C", c: Sys.temp > 80 ? Paper.accent : Paper.soft }
                    ]
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 40

                        Text {
                            text: row.modelData.label
                            font.family: Paper.serif
                            font.pixelSize: 13
                            color: Paper.ink
                        }
                        Text {
                            anchors.right: parent.right
                            text: row.modelData.text
                            font.family: Paper.mono
                            font.pixelSize: 12
                            color: Paper.soft
                        }
                        // Streifen
                        Rectangle {
                            id: track
                            y: 20
                            width: parent.width
                            height: 14
                            radius: 2
                            color: Paper.deep
                            Rectangle {
                                height: parent.height
                                radius: 2
                                color: row.modelData.c
                                // schiebt sich beim Oeffnen gestaffelt hinein
                                property real grow: m.progress >= 0.999 ? 1 : 0
                                Behavior on grow { NumberAnimation { duration: 700 + row.index * 120; easing.type: Easing.OutBack } }
                                width: Math.max(6, track.width * row.modelData.v * grow)
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                // umgeknicktes Ende
                                Rectangle {
                                    anchors.right: parent.right
                                    width: 6
                                    height: parent.height
                                    color: "#000000"
                                    opacity: 0.18
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Last  " + Sys.load
                    font.family: Paper.mono
                    font.pixelSize: 11
                    color: Paper.soft
                }
            }
        }
    }
}
