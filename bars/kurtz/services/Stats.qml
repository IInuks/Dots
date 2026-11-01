pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / temperature from /proc and /sys, polled every 2 s.
// Keeps a short history for the sparklines in the system popup.
//
// Temperature: resolved once by hwmon *name* (k10temp / coretemp /
// zenpower / cpu_thermal), because hwmonN numbering is not stable.
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real temp: -1        // deg C, -1 = unknown
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property var cores: []        // 0..1 per core
    property var cpuHistory: []   // last 40 samples, 0..1
    property var memHistory: []
    property string uptime: ""
    property var load: [0, 0, 0]

    readonly property int historyLength: 40
    property string _tempPath: ""
    property var _prev: []        // [idle,total] per line of /proc/stat

    function _push(arr, v) {
        const a = arr.slice(-(root.historyLength - 1));
        a.push(v);
        return a;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            upfile.reload();
            loadfile.reload();
            if (root._tempPath !== "")
                tempFile.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const lines = text().split("\n").filter(l => /^cpu/.test(l));
            const prev = root._prev;
            const next = [];
            const usage = [];
            for (let i = 0; i < lines.length; i++) {
                const p = lines[i].trim().split(/\s+/).slice(1).map(Number);
                const idle = p[3] + p[4];
                const total = p.reduce((a, b) => a + b, 0);
                next.push([idle, total]);
                if (prev[i]) {
                    const dt = total - prev[i][1];
                    usage.push(dt > 0 ? Math.max(0, Math.min(1, 1 - (idle - prev[i][0]) / dt)) : 0);
                } else {
                    usage.push(0);
                }
            }
            root._prev = next;
            if (prev.length > 0) {
                root.cpu = usage[0];
                root.cores = usage.slice(1);
                root.cpuHistory = root._push(root.cpuHistory, usage[0]);
            }
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const t = text();
            const get = k => {
                const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"));
                return m ? Number(m[1]) : 0;
            };
            const total = get("MemTotal");
            const avail = get("MemAvailable");
            if (total > 0) {
                root.mem = (total - avail) / total;
                root.memTotalGiB = total / 1048576;
                root.memUsedGiB = (total - avail) / 1048576;
                root.memHistory = root._push(root.memHistory, root.mem);
            }
        }
    }

    FileView {
        id: upfile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d > 0 ? d + "d " : "") + h + "h " + m + "m";
        }
    }

    FileView {
        id: loadfile
        path: "/proc/loadavg"
        printErrors: false
        onLoaded: root.load = text().split(" ").slice(0, 3).map(Number)
    }

    FileView {
        id: tempFile
        path: root._tempPath
        printErrors: false
        onLoaded: root.temp = Number(text()) / 1000
    }

    // Find the CPU sensor once.
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat $d/name 2>/dev/null); case $n in k10temp|coretemp|zenpower|cpu_thermal) echo $d/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: root._tempPath = text.trim()
        }
    }
}
