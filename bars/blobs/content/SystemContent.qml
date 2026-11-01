import QtQuick
import Quickshell.Io
import ".."

// Tab 2 (Systemmonitor) des rechten Blobs (Auftrag Abschnitt 6). Pollt nur,
// solange `active` true ist (Tab sichtbar UND Blob offen) -- kein Timer im
// Leerlauf. GPU-Zeile nur, wenn ein Sensor gefunden wurde (Cpu.qml).
Item {
    id: root

    required property bool active

    property real cpuPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real netRxKBs: 0
    property real netTxKBs: 0
    property string uptimeText: "–"

    // Deltas brauchen einen vorherigen Messpunkt -- null bis zum zweiten Tick.
    property var _prevCpu: null // {idle, total}
    property var _prevNet: null // {rx, tx, t}

    onActiveChanged: {
        if (!root.active) {
            // Naechstes Sichtbarwerden soll nicht aus einer laengst
            // veralteten Messung eine riesige Netzwerk-/CPU-Spitze errechnen.
            root._prevCpu = null;
            root._prevNet = null;
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
    }
    FileView {
        id: memFile
        path: "/proc/meminfo"
    }
    FileView {
        id: netFile
        path: "/proc/net/dev"
    }
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root._poll()
    }

    function _poll() {
        root._pollCpu();
        root._pollMem();
        root._pollNet();
        root._pollUptime();
    }

    function _pollCpu() {
        statFile.reload();
        const line = statFile.text().split("\n")[0]; // "cpu  user nice system idle iowait ..."
        const parts = line.trim().split(/\s+/).slice(1).map(Number);
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);
        if (root._prevCpu) {
            const dIdle = idle - root._prevCpu.idle;
            const dTotal = total - root._prevCpu.total;
            if (dTotal > 0)
                root.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal)));
        }
        root._prevCpu = {
            idle: idle,
            total: total
        };
    }

    function _pollMem() {
        memFile.reload();
        const lines = memFile.text().split("\n");
        let total = 0, avail = 0;
        for (const l of lines) {
            if (l.startsWith("MemTotal:"))
                total = parseInt(l.match(/\d+/)[0], 10);
            else if (l.startsWith("MemAvailable:"))
                avail = parseInt(l.match(/\d+/)[0], 10);
        }
        root.memTotalGiB = total / 1024 / 1024;
        root.memUsedGiB = (total - avail) / 1024 / 1024;
    }

    function _pollNet() {
        netFile.reload();
        // Erste zwei Zeilen sind der Header ("Inter-|..." / " face |...").
        const lines = netFile.text().split("\n").slice(2);
        let rx = 0, tx = 0;
        for (const l of lines) {
            const idx = l.indexOf(":");
            if (idx < 0)
                continue;
            const iface = l.slice(0, idx).trim();
            if (iface === "lo")
                continue;
            const cols = l.slice(idx + 1).trim().split(/\s+/).map(Number);
            rx += cols[0]; // rx bytes
            tx += cols[8]; // tx bytes (8 receive-Spalten davor)
        }
        const now = Date.now();
        if (root._prevNet) {
            const dt = (now - root._prevNet.t) / 1000;
            if (dt > 0) {
                root.netRxKBs = Math.max(0, (rx - root._prevNet.rx) / 1024 / dt);
                root.netTxKBs = Math.max(0, (tx - root._prevNet.tx) / 1024 / dt);
            }
        }
        root._prevNet = {
            rx: rx,
            tx: tx,
            t: now
        };
    }

    function _pollUptime() {
        uptimeFile.reload();
        const secs = parseFloat(uptimeFile.text().split(" ")[0]);
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        root.uptimeText = h + "h " + m + "m";
    }

    readonly property var _rows: {
        const rows = [
            {
                label: "CPU",
                value: Math.round(root.cpuPercent) + "%"
            },
            {
                label: "RAM",
                value: root.memUsedGiB.toFixed(1) + " / " + root.memTotalGiB.toFixed(1) + " GiB"
            }
        ];
        if (Cpu.gpuSensorFound)
            rows.push({
                label: "GPU",
                value: Math.round(Cpu.gpuTemperatureC) + "°"
            });
        rows.push({
            label: "Netz",
            value: root.netRxKBs.toFixed(0) + " / " + root.netTxKBs.toFixed(0) + " KB/s"
        });
        rows.push({
            label: "Uptime",
            value: root.uptimeText
        });
        return rows;
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root._rows

            Row {
                id: rowItem
                required property var modelData
                width: parent.width
                spacing: 8

                Text {
                    text: rowItem.modelData.label
                    color: Theme.surfaceInk
                    opacity: 0.6
                    font.pixelSize: 10
                    width: 44
                }
                Text {
                    text: rowItem.modelData.value
                    color: Theme.surfaceInk
                    font.pixelSize: 11
                }
            }
        }
    }
}
