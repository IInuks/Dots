pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Systemwerte und Ton. Bewusst ohne DBus/Pipewire-Bindings (die Session hat
// kein DBus, und Quickshells Pipewire-Anbindung verbindet sich nicht neu,
// wenn qs vor PipeWire startet) -- stattdessen /proc + pactl.
Singleton {
    id: root

    // ---- Systemwerte (alle 3 s, guenstig: ein kurzer sh-Aufruf) ----
    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real disk: 0         // 0..1
    property string diskText: ""
    property real temp: 0         // Grad C
    property real uptime: 0       // Sekunden
    property string load: ""
    property var cpuHistory: []   // letzte 40 Werte fuer die Skizze im Menue

    property var _lastCpu: null

    property Timer _statTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: stat.running = true
    }

    property Process _stat: Process {
        id: stat
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; df -P / | tail -1; " + "t=0; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); " + "if [ \"$n\" = k10temp ] || [ \"$n\" = coretemp ]; then t=$(cat $h/temp1_input); break; fi; done; echo temp $t; " + "echo up $(cut -d' ' -f1 /proc/uptime); echo load $(cut -d' ' -f1-3 /proc/loadavg)"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(t) {
        const lines = t.split("\n");
        for (const l of lines) {
            const f = l.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const v = f.slice(1).map(Number);
                const idle = v[3] + (v[4] || 0);
                const total = v.reduce((a, b) => a + b, 0);
                if (_lastCpu) {
                    const dt = total - _lastCpu.total;
                    const di = idle - _lastCpu.idle;
                    cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                    const h = cpuHistory.slice(-39);
                    h.push(cpu);
                    cpuHistory = h;
                }
                _lastCpu = {
                    total: total,
                    idle: idle
                };
            } else if (f[0] === "MemTotal:") {
                memTotalGb = Number(f[1]) / 1048576;
            } else if (f[0] === "MemAvailable:") {
                const avail = Number(f[1]) / 1048576;
                memUsedGb = memTotalGb - avail;
                mem = memTotalGb > 0 ? memUsedGb / memTotalGb : 0;
            } else if (f[0].startsWith("/dev") || f[5] === "/") {
                disk = Number(String(f[4]).replace("%", "")) / 100;
                diskText = (Number(f[2]) / 1048576).toFixed(0) + " / " + (Number(f[1]) / 1048576).toFixed(0) + " GB";
            } else if (f[0] === "temp") {
                temp = Number(f[1]) / 1000;
            } else if (f[0] === "up") {
                uptime = Number(f[1]);
            } else if (f[0] === "load") {
                load = f.slice(1).join("  ");
            }
        }
    }

    function uptimeText() {
        const s = Math.floor(uptime);
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d > 0 ? d + " T " : "") + h + " Std " + m + " Min";
    }

    // ---- Ton ueber pactl ----
    property real volume: 0       // 0..1.5
    property bool muted: false
    property string sinkName: ""
    property var sinks: []        // [{name, description}]

    function setVolume(v) {
        v = Math.max(0, Math.min(1.5, v));
        volume = v;
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(v * 100) + "%"]);
    }
    function toggleMute() {
        muted = !muted;
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]);
    }
    function setSink(n) {
        sinkName = n;
        Quickshell.execDetached(["pactl", "set-default-sink", n]);
    }
    function refreshSinks() {
        sinksProc.running = true;
    }

    property Process _vol: Process {
        id: vol
        command: ["sh", "-c", "pactl get-default-sink; pactl get-sink-volume @DEFAULT_SINK@ | head -1; pactl get-sink-mute @DEFAULT_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.sinkName = (l[0] || "").trim();
                const m = /(\d+)%/.exec(l[1] || "");
                if (m)
                    root.volume = Number(m[1]) / 100;
                root.muted = /yes|ja/i.test(l[2] || "");
            }
        }
    }

    property Process _sinks: Process {
        id: sinksProc
        command: ["pactl", "-f", "json", "list", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sinks = JSON.parse(text).map(s => ({
                                name: s.name,
                                description: s.description || s.name
                            }));
                } catch (e) {}
            }
        }
    }

    // Aenderungen kommen als Events; danach (gebuendelt) neu abfragen.
    property Process _sub: Process {
        id: sub
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (/sink|server/.test(line))
                    volDebounce.restart();
            }
        }
        onExited: subRestart.start()
    }
    property Timer _volDebounce: Timer {
        id: volDebounce
        interval: 80
        onTriggered: vol.running = true
    }
    property Timer _subRestart: Timer {
        id: subRestart
        interval: 2000
        onTriggered: {
            sub.running = true;
            vol.running = true;
        }
    }
}
