pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / Temperatur aus /proc und /sys. Normal alle 3 s, solange das
// System-Menü offen ist jede Sekunde (für die Verlaufskurve).
Singleton {
    id: root

    property real cpu: 0
    property real mem: 0
    property real memUsed: 0     // GiB
    property real memTotal: 0
    property real temp: -1
    property var cores: []
    property var cpuHist: []
    property var memHist: []
    property string uptime: ""
    property var load: [0, 0, 0]
    readonly property int histLen: 60

    property string _tempPath: ""
    property var _prev: []

    function _push(a, v) { const b = a.slice(-(histLen - 1)); b.push(v); return b; }

    Timer {
        interval: Ui.openId === "system" ? 1000 : 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); meminfo.reload(); up.reload(); loadavg.reload();
            if (root._tempPath) tempFile.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n").filter(l => /^cpu/.test(l));
            const next = [], use = [];
            for (let i = 0; i < lines.length; i++) {
                const p = lines[i].trim().split(/\s+/).slice(1).map(Number);
                const idle = p[3] + p[4], total = p.reduce((a, b) => a + b, 0);
                next.push([idle, total]);
                const pr = root._prev[i];
                const dt = pr ? total - pr[1] : 0;
                use.push(dt > 0 ? Math.max(0, Math.min(1, 1 - (idle - pr[0]) / dt)) : 0);
            }
            const first = root._prev.length === 0;
            root._prev = next;
            if (first) return;
            root.cpu = use[0];
            root.cores = use.slice(1);
            root.cpuHist = root._push(root.cpuHist, use[0]);
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => { const m = new RegExp("^" + k + ":\\s+(\\d+)", "m").exec(t); return m ? Number(m[1]) : 0; };
            const total = get("MemTotal"), avail = get("MemAvailable");
            root.memTotal = total / 1048576;
            root.memUsed = (total - avail) / 1048576;
            root.mem = total > 0 ? (total - avail) / total : 0;
            root.memHist = root._push(root.memHist, root.mem);
        }
    }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d > 0 ? d + " d " : "") + h + " h " + m + " min";
        }
    }
    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).map(Number)
    }
    FileView {
        id: tempFile
        path: root._tempPath
        printErrors: false
        onLoaded: root.temp = Number(text()) / 1000
    }
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); case $n in k10temp|coretemp|zenpower|cpu_thermal) echo $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector { onStreamFinished: root._tempPath = text.trim() }
    }
}
