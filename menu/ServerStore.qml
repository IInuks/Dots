pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Remote server for the "Server" tab: stats over SSH (Tailscale), sampled
// every 3 s by salbei's bars/salbei/scripts/server.sh -- one script, one
// shared ssh control socket for the tab and salbei's own Server page.
// Polls only while the tab page exists (watchers) and the menu is visible.
// The history (CPU / RAM, last 3 min) lives here, because the tab page is
// recreated on every tab switch.
//
// Host / fallback IP / user are saved to menu-server.json (we're the only
// writer, like BlobStore).
QtObject {
    id: root

    readonly property string host: file.adapter.host
    readonly property string fallback: file.adapter.fallback
    readonly property string user: file.adapter.user
    readonly property string target: (user !== "" ? user + "@" : "") + host

    property int watchers: 0
    readonly property bool active: watchers > 0 && MenuState.visible

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
    property var procs: []               // [{cpu, mem, name}], cpu/mem in % (ps: average since start)

    readonly property int historyLength: 60   // samples, 3 s each
    property var cpuHistory: []
    property var memHistory: []

    readonly property var rootDisk: disks.find(d => d.mount === "/") ?? disks[0] ?? { mount: "/", used: 0, total: 0 }

    readonly property string script: Quickshell.env("HOME") + "/quickdots/bars/salbei/scripts/server.sh"
    function args(mode: string): var { return [script, mode, host, fallback, user]; }

    function openShell(): void { Quickshell.execDetached(["kitty", "-e", "sh"].concat(args("shell"))); }
    function setupKey(): void { Quickshell.execDetached(["kitty", "-e", "sh"].concat(args("setup"))); }

    function setHost(h: string, fb: string, u: string): void {
        h = h.trim();
        if (h === "") return;
        if (h === host && fb.trim() === fallback && u.trim() === user) return;
        file.adapter.host = h;
        file.adapter.fallback = fb.trim();
        file.adapter.user = u.trim();
        file.writeAdapter();
        _reset();
        if (active) poll();
    }

    function poll(): void {
        if (_proc.running) return;
        if (status === "idle") status = "connecting";
        _proc.running = true;
    }

    // -- formatting ----------------------------------------------------
    function gib(b: real): string { return (b / 1073741824).toFixed(1) + " GiB"; }
    function size(b: real): string { return b >= 1099511627776 ? (b / 1099511627776).toFixed(2) + " TiB" : gib(b); }
    function rate(b: real): string {
        return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s"
             : b >= 1024 ? Math.round(b / 1024) + " kB/s" : Math.round(b) + " B/s";
    }
    function formatUptime(s: real): string {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return d > 0 ? d + " d " + h + " h" : h > 0 ? h + " h " + m + " min" : m + " min";
    }

    // -- internals -------------------------------------------------------
    property real _lastIdle: 0
    property real _lastTotal: 0
    property real _lastRx: 0
    property real _lastTx: 0
    property real _lastTime: 0

    function _reset(): void {
        status = "connecting";
        hostname = "";
        cpuHistory = [];
        memHistory = [];
        procs = [];
        disks = [];
        _lastTotal = 0;
        _lastTime = 0;
    }

    function _push(list: var, v: real): var {
        const l = list.concat([v]);
        return l.length > historyLength ? l.slice(l.length - historyLength) : l;
    }

    // Same format as salbei's services/Server.qml (plus the "P" lines).
    function _parse(text: string): void {
        const mem = {};
        const ds = [];
        const ps = [];
        let t = NaN;
        let cpuSampled = false;
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            switch (f[0]) {
            case "H": hostname = f[1] ?? ""; kernel = f[2] ?? ""; break;
            case "cpu": {
                const n = f.slice(1).map(Number);
                const idle = n[3] + (n[4] || 0);
                const total = n.reduce((a, b) => a + b, 0);
                if (_lastTotal > 0 && total > _lastTotal) {
                    cpu = 1 - (idle - _lastIdle) / (total - _lastTotal);
                    cpuSampled = true;
                }
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
            case "P": ps.push({ cpu: Number(f[1]), mem: Number(f[2]), name: f.slice(3).join(" ") }); break;
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
        procs = ps;
        if (cpuSampled) {
            cpuHistory = _push(cpuHistory, cpu);
            memHistory = _push(memHistory, memTotal > 0 ? memUsed / memTotal : 0);
        }
    }

    onActiveChanged: if (!active && status !== "ok") status = "idle"

    property Process _proc: Process {
        command: root.args("stats")
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code === 0) {
                root._parse(out.text);
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

    property Timer _timer: Timer {
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/menu-server.json"
        watchChanges: false
        atomicWrites: true
        printErrors: false
        adapter: JsonAdapter {
            property string host: "PRIVATE_VALUE"                // Tailscale name
            property string fallback: "TAILSCALE_FALLBACK_IP"   // used if the name doesn't resolve
            property string user: ""                     // empty = same as local user
        }
    }
}
