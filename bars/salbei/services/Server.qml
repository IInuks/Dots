pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Remote server stats over SSH (scripts/server.sh). Polls only while
// `watchers` > 0 (Server page open). Connection details are stored locally
// and shared with the quickdots menu.
Singleton {
    id: root

    property int watchers: 0

    // "idle" | "connecting" | "ok" | "auth" (no key accepted)
    // | "check" (Tailscale SSH wants a browser login) | "offline"
    property string status: "idle"
    property string error: ""
    property string hostname: ""
    property string kernel: ""
    property real cpu: 0                 // 0..1
    property real memUsed: 0             // bytes
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real uptime: 0              // seconds
    property var load: [0, 0, 0]
    property int cores: 1
    property real temp: NaN              // °C
    property real rxRate: 0              // bytes/s
    property real txRate: 0
    property var disks: []               // [{mount, used, total}]

    readonly property string host: file.adapter.host
    readonly property string fallback: file.adapter.fallback
    readonly property string user: file.adapter.user
    readonly property string target: (user !== "" ? user + "@" : "") + host
    readonly property string script: Quickshell.shellDir + "/scripts/server.sh"
    function args(mode) { return [script, mode, host, fallback, user]; }

    function openShell() { Ui.terminal(["-e", "sh"].concat(args("shell"))); }
    function setupKey() { Ui.terminal(["-e", "sh"].concat(args("setup"))); }

    property real _lastIdle: 0
    property real _lastTotal: 0
    property real _lastRx: 0
    property real _lastTx: 0
    property real _lastTime: 0

    function parse(text) {
        const mem = {};
        const ds = [];
        let t = NaN;
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            switch (f[0]) {
            case "H": hostname = f[1] ?? ""; kernel = f[2] ?? ""; break;
            case "cpu": {
                const n = f.slice(1).map(Number);
                const idle = n[3] + (n[4] || 0);
                const total = n.reduce((a, b) => a + b, 0);
                if (_lastTotal > 0 && total > _lastTotal) cpu = 1 - (idle - _lastIdle) / (total - _lastTotal);
                _lastIdle = idle;
                _lastTotal = total;
                break;
            }
            case "U": uptime = parseFloat(f[1]) || 0; break;
            case "L": load = f.slice(1, 4).map(Number); cores = parseInt(f[4]) || 1; break;
            case "N": {
                const now = Date.now() / 1000, rx = Number(f[1]), tx = Number(f[2]);
                if (_lastTime > 0 && now > _lastTime) {
                    rxRate = Math.max(0, (rx - _lastRx) / (now - _lastTime));
                    txRate = Math.max(0, (tx - _lastTx) / (now - _lastTime));
                }
                _lastRx = rx; _lastTx = tx; _lastTime = now;
                break;
            }
            case "T":
                // first CPU-ish sensor wins
                if (isNaN(t) && /k10temp|zenpower|coretemp|cpu_thermal|acpitz/.test(f[1])) t = parseInt(f[2]) / 1000;
                break;
            case "D": ds.push({ total: Number(f[1]), used: Number(f[2]), mount: f.slice(3).join(" ") }); break;
            default: {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) mem[m[1]] = parseInt(m[2]) * 1024;
            }
            }
        }
        if (mem.MemTotal) {
            memTotal = mem.MemTotal;
            memUsed = mem.MemTotal - (mem.MemAvailable ?? 0);
            swapTotal = mem.SwapTotal ?? 0;
            swapUsed = swapTotal - (mem.SwapFree ?? 0);
        }
        temp = t;
        disks = ds;
    }

    Process {
        id: proc
        command: root.args("stats")
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code === 0) {
                root.parse(out.text);
                root.status = "ok";
                root.error = "";
                return;
            }
            const e = err.text.trim();
            root.error = e.split("\n").pop() ?? "";
            root.status = /login\.tailscale\.com/.test(e) ? "check"
                : /Permission denied|Host key verification/.test(e) ? "auth" : "offline";
            root._lastTotal = 0;
            root._lastTime = 0;
        }
    }

    function poll() {
        if (proc.running || host === "") return;
        if (status === "idle") status = "connecting";
        proc.running = true;
    }

    onWatchersChanged: if (watchers === 0) status = "idle"

    Timer {
        interval: Theme.serverInterval
        running: root.watchers > 0 && root.host !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/menu-server.json"
        watchChanges: true
        printErrors: false
        adapter: JsonAdapter {
            property string host: ""
            property string fallback: ""
            property string user: ""
        }
    }
}
