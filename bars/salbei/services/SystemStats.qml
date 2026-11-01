pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// CPU %, memory, temperatures, uptime and disk usage. CPU/memory/temp poll every
// Theme.statsInterval; disk only while `diskWatchers` > 0 (System page open).
Singleton {
    id: root

    property real cpu: 0                 // 0..1
    property real memUsed: 0             // bytes
    property real memTotal: 0
    property real cpuTemp: NaN           // °C
    property real gpuTemp: NaN
    property real nvmeTemp: NaN
    property real uptime: 0              // seconds
    property real diskUsed: 0
    property real diskTotal: 0
    property int diskWatchers: 0
    property string kernel: ""
    property string shellVersion: ""
    readonly property string user: Quickshell.env("USER") ?? "user"
    property string host: ""

    readonly property string memText: (memUsed / 1073741824).toFixed(1) + " GiB"
    readonly property string cpuText: Math.round(cpu * 100) + "%"
    readonly property string tempText: isNaN(cpuTemp) ? "–" : Math.round(cpuTemp) + "°C"

    function formatUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        const parts = [];
        if (d) parts.push(d + (d === 1 ? " day" : " days"));
        if (h) parts.push(h + (h === 1 ? " hour" : " hours"));
        if (!d) parts.push(m + (m === 1 ? " minute" : " minutes"));
        return parts.join(", ");
    }

    property var _lastIdle: 0
    property var _lastTotal: 0

    // hwmon temp files, resolved once
    property string _cpuTempPath: ""
    property string _gpuTempPath: ""
    property string _nvmeTempPath: ""

    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }
    FileView { id: uptimeFile; path: "/proc/uptime" }
    FileView { id: cpuTempFile; path: root._cpuTempPath }
    FileView { id: gpuTempFile; path: root._gpuTempPath }
    FileView { id: nvmeTempFile; path: root._nvmeTempPath }

    function readTemp(view, path) {
        if (path === "") return NaN;
        view.reload();
        const v = parseInt(view.text());
        return isNaN(v) ? NaN : v / 1000;
    }

    function poll() {
        statFile.reload();
        const cpuLine = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (cpuLine.length >= 4) {
            const idle = cpuLine[3] + (cpuLine[4] || 0);
            const total = cpuLine.reduce((a, b) => a + b, 0);
            const dt = total - _lastTotal;
            if (_lastTotal > 0 && dt > 0) cpu = 1 - (idle - _lastIdle) / dt;
            _lastIdle = idle;
            _lastTotal = total;
        }

        memFile.reload();
        const mem = {};
        for (const l of memFile.text().split("\n")) {
            const m = l.match(/^(\w+):\s+(\d+)/);
            if (m) mem[m[1]] = parseInt(m[2]) * 1024;
        }
        if (mem.MemTotal) {
            memTotal = mem.MemTotal;
            memUsed = mem.MemTotal - (mem.MemAvailable ?? mem.MemFree);
        }

        uptimeFile.reload();
        uptime = parseFloat(uptimeFile.text()) || 0;

        cpuTemp = readTemp(cpuTempFile, _cpuTempPath);
        gpuTemp = readTemp(gpuTempFile, _gpuTempPath);
        nvmeTemp = readTemp(nvmeTempFile, _nvmeTempPath);
    }

    Timer {
        interval: Theme.statsInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // find hwmon sensors: "<name> <path-to-temp1_input>" per line
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -r \"$h/temp1_input\" ] && echo \"$(cat $h/name) $h/temp1_input\"; done; uname -r >&2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const l of text.trim().split("\n")) {
                    const [name, path] = l.split(" ");
                    if (name && !found[name]) found[name] = path;
                }
                root._cpuTempPath = found.k10temp ?? found.zenpower ?? found.coretemp ?? found.cpu_thermal ?? "";
                root._gpuTempPath = found.amdgpu ?? found.nouveau ?? found.nvidia ?? "";
                root._nvmeTempPath = found.nvme ?? "";
            }
        }
        stderr: StdioCollector { onStreamFinished: root.kernel = text.trim() }
    }

    Process {
        running: true
        command: ["sh", "-c", "qs --version | head -1; cat /etc/hostname"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const v = (l[0] ?? "").match(/\d+\.\d+(\.\d+)?/);
                root.shellVersion = v ? "Quickshell v" + v[0] : "Quickshell";
                root.host = (l[1] ?? "").trim();
            }
        }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")[1];
                if (!l) return;
                const [size, used] = l.trim().split(/\s+/).map(Number);
                root.diskTotal = size;
                root.diskUsed = used;
            }
        }
    }
    Timer {
        interval: 30000
        running: root.diskWatchers > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
