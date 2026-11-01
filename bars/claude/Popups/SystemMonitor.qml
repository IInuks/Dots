import QtQuick
import Quickshell.Io
import ".."
import "../Bar"

// Real in-shell system monitor for the CPU gauge's click: CPU/RAM rings,
// uptime, top processes by CPU -- polled only while open, no external
// terminal app involved.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.monitorWidth
    panelHeight: Metrics.monitorHeight

    property real cpuValue: 0
    property real memValue: 0
    property string memLabel: "-- / -- GB"
    property string uptimeLabel: "--"
    property var procs: []

    property var _prevCpuTotals: null

    function _parseCpu(line) {
        const parts = line.trim().split(/\s+/).slice(1).map(Number);
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);
        return { idle, total };
    }

    function refresh() {
        statProc.running = false; statProc.running = true;
        memProc.running = false; memProc.running = true;
        uptimeProc.running = false; uptimeProc.running = true;
        procsProc.running = false; procsProc.running = true;
    }

    Timer {
        interval: 2000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: statProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = root._parseCpu(text);
                if (root._prevCpuTotals) {
                    const dTotal = cur.total - root._prevCpuTotals.total;
                    const dIdle = cur.idle - root._prevCpuTotals.idle;
                    if (dTotal > 0)
                        root.cpuValue = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
                }
                root._prevCpuTotals = cur;
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, avail = 0;
                for (const l of text.trim().split("\n")) {
                    const m = l.trim().split(/\s+/);
                    const kb = Number(m[1]);
                    if (m[0].startsWith("MemTotal")) total = kb;
                    else if (m[0].startsWith("MemAvailable")) avail = kb;
                }
                if (total > 0) {
                    const used = total - avail;
                    root.memValue = used / total;
                    root.memLabel = (used / 1048576).toFixed(1) + " / " + (total / 1048576).toFixed(1) + " GB";
                }
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "cut -d. -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const secs = parseInt(text.trim());
                root.uptimeLabel = Math.floor(secs / 3600) + "h " + Math.floor((secs % 3600) / 60) + "m";
            }
        }
    }

    Process {
        id: procsProc
        command: ["sh", "-c", "ps -eo comm,%cpu --sort=-%cpu --no-headers | head -5"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.procs = text.trim().split("\n").filter(l => l.length > 0).map(l => {
                    const parts = l.trim().split(/\s+/);
                    const cpu = parts.pop();
                    return { name: parts.join(" "), cpu: cpu };
                });
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Row {
            width: parent.width
            spacing: 24

            Column {
                spacing: 6
                Meter {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: 54; implicitHeight: 54
                    glyphName: "cpu"
                    ringColor: root.cpuValue > 0.85 ? Chroma.bad : Chroma.accent
                    value: root.cpuValue
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.cpuValue * 100) + "% CPU"
                    color: Chroma.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 10
                }
            }

            Column {
                spacing: 6
                Meter {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: 54; implicitHeight: 54
                    glyphName: "drop"
                    ringColor: root.memValue > 0.85 ? Chroma.bad : Chroma.accent2
                    value: root.memValue
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.memLabel
                    color: Chroma.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 10
                }
            }

            Column {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Laufzeit"; color: Chroma.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 10 }
                Text { text: root.uptimeLabel; color: Chroma.text; font.family: Metrics.fontFamily; font.pixelSize: 13 }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Chroma.textFaint, 0.2) }

        Column {
            width: parent.width
            spacing: 6

            Text { text: "Top-Prozesse"; color: Chroma.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }

            Repeater {
                model: root.procs
                delegate: Row {
                    required property var modelData
                    width: parent.width

                    Text {
                        width: parent.width - 50
                        text: modelData.name
                        color: Chroma.text
                        font.family: Metrics.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Text {
                        width: 50
                        horizontalAlignment: Text.AlignRight
                        text: modelData.cpu + "%"
                        color: Chroma.textFaint
                        font.family: Metrics.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
