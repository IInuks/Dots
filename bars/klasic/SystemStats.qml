import QtQuick
import Quickshell.Io

// CPU/RAM/temperature, polled every 2s. Same /proc + hwmon approach as
// bars/shellbar/SysMonData.qml (already proven on this machine), trimmed to
// just the three metrics klasic shows -- no shared consumer beyond this bar,
// so it's a plain component instead of a singleton.
Row {
    id: root
    spacing: 12

    property real cpuPercent: 0
    property real ramUsedGB: 0
    property real ramTotalGB: 0
    property real cpuTemp: 0

    property real _prevIdle: 0
    property real _prevTotal: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            hwmonProc.running = false;
            hwmonProc.running = true;
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const line = statFile.text().split("\n")[0];
            const parts = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + parts[4];
            const total = parts.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._prevIdle;
            const dTotal = total - root._prevTotal;
            if (root._prevTotal > 0 && dTotal > 0) {
                root.cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal));
            }
            root._prevIdle = idle;
            root._prevTotal = total;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const text = memFile.text();
            const total = Number((/MemTotal:\s+(\d+)/.exec(text) || [0, 0])[1]);
            const avail = Number((/MemAvailable:\s+(\d+)/.exec(text) || [0, 0])[1]);
            if (total > 0) {
                root.ramUsedGB = (total - avail) / 1048576;
                root.ramTotalGB = total / 1048576;
            }
        }
    }

    Process {
        id: hwmonProc
        command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp1_input; do n=$(cat \"$(dirname \"$f\")/name\" 2>/dev/null); t=$(cat \"$f\" 2>/dev/null); echo \"$n:$t\"; done 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const priority = ["k10temp", "coretemp", "zenpower", "cpu_thermal"];
                let picked = null;
                for (const name of priority) {
                    const hit = lines.find(l => l.startsWith(name + ":"));
                    if (hit) { picked = hit; break; }
                }
                if (!picked && lines.length > 0) picked = lines[0];
                if (picked) {
                    const millideg = Number(picked.split(":")[1]);
                    if (!isNaN(millideg)) root.cpuTemp = millideg / 1000;
                }
            }
        }
    }

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "cpu"; size: 13; tint: Theme.textMuted; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Math.round(root.cpuPercent) + "%"
            color: Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "ram"; size: 13; tint: Theme.textMuted; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: root.ramUsedGB.toFixed(1) + "GB"
            color: Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "temp"; size: 13; tint: Theme.textMuted; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Math.round(root.cpuTemp) + "°C"
            color: Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
