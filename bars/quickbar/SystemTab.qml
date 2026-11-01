import QtQuick
import Quickshell.Io

// Only exists while this tab is selected and the big menu is open (the
// Loader in BigMenu.qml destroys it otherwise), so polling here doesn't
// cost anything while the bar is just sitting closed.
Column {
    id: root
    spacing: 14

    property real cpuFraction: 0
    property real _prevIdle: -1
    property real _prevTotal: -1
    property string ramText: "…"
    property real ramFraction: 0
    property string gpuText: "…"
    property real gpuFraction: 0
    property string tempText: "…"
    property real tempFraction: 0
    property string diskText: "…"
    property real diskFraction: 0
    property var topProcs: []

    readonly property string _marker: "@@Q@@"

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Process {
        id: statsProc
        command: ["sh", "-c",
            "cat /proc/stat | head -1; echo " + root._marker + ";" +
            "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'; echo " + root._marker + ";" +
            "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null; echo " + root._marker + ";" +
            "cat /sys/class/hwmon/hwmon3/temp1_input 2>/dev/null; echo " + root._marker + ";" +
            "df -k / | tail -1; echo " + root._marker + ";" +
            "ps --sort=-%cpu -eo comm,%cpu --no-headers | head -5"
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(text) {
        const parts = text.split(root._marker);
        if (parts.length < 6) return;

        // CPU
        const cpuLine = parts[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = cpuLine[3] + cpuLine[4];
        const total = cpuLine.reduce((a, b) => a + b, 0);
        if (root._prevTotal >= 0) {
            const dIdle = idle - root._prevIdle;
            const dTotal = total - root._prevTotal;
            if (dTotal > 0) root.cpuFraction = 1 - dIdle / dTotal;
        }
        root._prevIdle = idle;
        root._prevTotal = total;

        // RAM
        const memLines = parts[1].trim().split("\n");
        let memTotal = 0, memAvail = 0;
        for (const l of memLines) {
            const m = l.match(/(\w+):\s+(\d+)/);
            if (!m) continue;
            if (m[1] === "MemTotal") memTotal = parseInt(m[2]);
            if (m[1] === "MemAvailable") memAvail = parseInt(m[2]);
        }
        if (memTotal > 0) {
            const usedGb = (memTotal - memAvail) / 1048576;
            const totalGb = memTotal / 1048576;
            root.ramFraction = 1 - memAvail / memTotal;
            root.ramText = usedGb.toFixed(1) + " / " + totalGb.toFixed(1) + " GB";
        }

        // GPU
        const gpuLine = parts[2].trim();
        if (gpuLine.length > 0) {
            const g = gpuLine.split(",").map(s => parseFloat(s.trim()));
            root.gpuFraction = g[0] / 100;
            root.gpuText = Math.round(g[0]) + "% · " + Math.round(g[1]) + "°C";
        } else {
            root.gpuText = "n/v";
        }

        // Temp
        const tempRaw = parseFloat(parts[3].trim());
        if (!isNaN(tempRaw)) {
            const c = tempRaw / 1000;
            root.tempFraction = Math.min(1, c / 90);
            root.tempText = c.toFixed(0) + "°C";
        }

        // Disk
        const diskFields = parts[4].trim().split(/\s+/);
        if (diskFields.length >= 5) {
            const usedKb = parseInt(diskFields[2]);
            const totalKb = parseInt(diskFields[1]);
            root.diskFraction = usedKb / totalKb;
            root.diskText = (usedKb / 1048576).toFixed(0) + " / " + (totalKb / 1048576).toFixed(0) + " GB";
        }

        // Top processes
        const procLines = parts[5].trim().split("\n").filter(l => l.length > 0);
        root.topProcs = procLines.map(l => {
            const m = l.trim().match(/^(.+?)\s+([\d.]+)$/);
            return m ? { name: m[1], cpu: parseFloat(m[2]) } : null;
        }).filter(p => p !== null);
    }

    MeterRow { label: "CPU"; valueText: Math.round(root.cpuFraction * 100) + "%"; fraction: root.cpuFraction; barColor: Theme.accent }
    MeterRow { label: "RAM"; valueText: root.ramText; fraction: root.ramFraction; barColor: Theme.accent2 }
    MeterRow { label: "GPU"; valueText: root.gpuText; fraction: root.gpuFraction; barColor: Theme.accent }
    MeterRow { label: "Temperatur"; valueText: root.tempText; fraction: root.tempFraction; barColor: Theme.warn }
    MeterRow { label: "Datenträger"; valueText: root.diskText; fraction: root.diskFraction; barColor: Theme.accent2 }

    Column {
        width: parent.width
        spacing: 6
        topPadding: 4

        Text { text: "Top-Prozesse"; color: Theme.textDim; font.pixelSize: 11 }

        Repeater {
            model: root.topProcs
            delegate: Item {
                required property var modelData
                width: root.width
                height: 18
                Text { anchors.left: parent.left; text: modelData.name; color: Theme.text; font.pixelSize: 12 }
                Text { anchors.right: parent.right; text: modelData.cpu.toFixed(1) + "%"; color: Theme.textDim; font.pixelSize: 12 }
            }
        }
    }
}
