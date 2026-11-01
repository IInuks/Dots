pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU/GPU/RAM polling plus brightness control for the left/right island
// widgets (bar prompt section 4: cpu/gpu/memory/brightness rows). No
// Quickshell-native service covers any of these (unlike volume/battery/
// wifi/bluetooth, which the widgets read straight from Quickshell.Services.
// Pipewire/UPower and Quickshell.Networking/Bluetooth) -- same reasoning
// bars/lucid/SystemService.qml already used on this system, reused here
// with ricev2's own polling cadences (bar prompt section 8: "Helligkeit
// alle 5s, Systemwerte ~2s" -- two separate timers, not lucid's single one).
//
// CPU temp: this machine has no /sys/class/thermal zone and no lm-sensors
// (`sensors` isn't installed) -- checked, not assumed. It does have a
// k10temp hwmon device (AMD Tctl, confirmed via `cat
// /sys/class/hwmon/hwmon*/name`). hwmonN numbering isn't guaranteed stable
// across reboots, so the k10temp path is resolved once at startup by name
// instead of hardcoding "hwmon3".
//
// GPU: `nvidia-smi` (NVIDIA card, per this system's own hardware -- see
// memory) gives utilization+temperature in one call; gpuAvailable gates the
// widget off if nvidia-smi isn't there or the query fails, same present-
// gating pattern as brightnessAvailable below.
QtObject {
    id: root

    property real cpuPercent: 0
    property int cpuTempC: -1
    property bool gpuAvailable: false
    property real gpuPercent: 0
    property int gpuTempC: 0
    property real memPercent: 0

    // Extra detail for the system-monitor dropdown (Bar/menus/
    // SysMonitorDropdown.qml, left-island click) -- the compact bar widgets
    // above only ever needed the aggregate numbers, this is additional
    // detail pulled from the same /proc files + nvidia-smi call, on the
    // same ~2s timer.
    property var cpuCorePercents: []
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real gpuVramUsedGiB: 0
    property real gpuVramTotalGiB: 0
    property var loadAvg: [0, 0, 0]
    property string uptimeText: ""

    property bool brightnessAvailable: false
    property real brightness: 0 // 0..1
    property int _brightnessMax: 0

    property real _prevIdle: 0
    property real _prevTotal: 0
    property var _prevCoreIdle: []
    property var _prevCoreTotal: []
    property string _cpuTempPath: ""

    // -- CPU/GPU/RAM: ~2s (bar prompt section 8) -----------------------
    property Timer _statsTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            loadavgFile.reload();
            uptimeFile.reload();
            gpuProc.running = false;
            gpuProc.running = true;
            if (root._cpuTempPath.length > 0) {
                cpuTempFile.reload();
            }
        }
    }

    // -- Brightness: 5s (bar prompt section 8) -------------------------
    property Timer _brightnessTimer: Timer {
        interval: 5000
        running: root.brightnessAvailable
        repeat: true
        onTriggered: {
            brightnessGetProc.running = false;
            brightnessGetProc.running = true;
        }
    }

    property FileView _statFile: FileView {
        id: statFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const lines = statFile.text().split("\n");
            const parts = lines[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + parts[4];
            const total = parts.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._prevIdle;
            const dTotal = total - root._prevTotal;
            if (root._prevTotal > 0 && dTotal > 0)
                root.cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal));
            root._prevIdle = idle;
            root._prevTotal = total;

            // Per-core lines ("cpu0 ...", "cpu1 ...", ...) directly follow
            // the aggregate "cpu ..." line, in order, until the first
            // non-cpuN line (e.g. "intr").
            const cores = [];
            for (let i = 1; i < lines.length; i++) {
                if (!/^cpu\d/.test(lines[i]))
                    break;
                const coreParts = lines[i].trim().split(/\s+/).slice(1).map(Number);
                const coreIdle = coreParts[3] + coreParts[4];
                const coreTotal = coreParts.reduce((a, b) => a + b, 0);
                const idx = cores.length;
                const prevIdle = root._prevCoreIdle[idx] || 0;
                const prevTotal = root._prevCoreTotal[idx] || 0;
                const dCoreIdle = coreIdle - prevIdle;
                const dCoreTotal = coreTotal - prevTotal;
                let pct = 0;
                if (prevTotal > 0 && dCoreTotal > 0)
                    pct = Math.max(0, Math.min(100, 100 * (dCoreTotal - dCoreIdle) / dCoreTotal));
                cores.push(pct);
                root._prevCoreIdle[idx] = coreIdle;
                root._prevCoreTotal[idx] = coreTotal;
            }
            root.cpuCorePercents = cores;
        }
    }

    property FileView _memFile: FileView {
        id: memFile
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const text = memFile.text();
            const total = Number((/MemTotal:\s+(\d+)/.exec(text) || [0, 0])[1]);
            const avail = Number((/MemAvailable:\s+(\d+)/.exec(text) || [0, 0])[1]);
            if (total > 0) {
                root.memPercent = 100 * (total - avail) / total;
                root.memTotalGiB = total / 1048576;
                root.memUsedGiB = (total - avail) / 1048576;
            }
        }
    }

    property FileView _cpuTempFile: FileView {
        id: cpuTempFile
        path: root._cpuTempPath
        printErrors: false
        onLoaded: {
            const n = Number(cpuTempFile.text().trim());
            if (!isNaN(n))
                root.cpuTempC = Math.round(n / 1000);
        }
    }

    // Resolves the k10temp hwmon device by name once at startup (see
    // header comment -- hwmonN numbering isn't stable across reboots).
    property Process _cpuTempResolveProc: Process {
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$d/name\" 2>/dev/null)\" = k10temp ] && { echo \"$d/temp1_input\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p.length > 0)
                    root._cpuTempPath = p;
            }
        }
    }

    property Process _gpuProc: Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",").map(s => Number(s.trim()));
                if (parts.length === 4 && parts.every(n => !isNaN(n))) {
                    root.gpuPercent = parts[0];
                    root.gpuTempC = parts[1];
                    root.gpuVramUsedGiB = parts[2] / 1024;
                    root.gpuVramTotalGiB = parts[3] / 1024;
                    root.gpuAvailable = true;
                } else {
                    root.gpuAvailable = false;
                }
            }
        }
    }

    property FileView _loadavgFile: FileView {
        id: loadavgFile
        path: "/proc/loadavg"
        printErrors: false
        onLoaded: {
            const parts = loadavgFile.text().trim().split(/\s+/).slice(0, 3).map(Number);
            if (parts.length === 3 && parts.every(n => !isNaN(n)))
                root.loadAvg = parts;
        }
    }

    property FileView _uptimeFile: FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const seconds = Number(uptimeFile.text().trim().split(/\s+/)[0]);
            if (isNaN(seconds))
                return;
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            root.uptimeText = h > 0 ? (h + "h " + m + "m") : (m + "m");
        }
    }

    property Process _brightnessMaxProc: Process {
        id: brightnessMaxProc
        command: ["sh", "-c", "brightnessctl m 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Number(text.trim());
                if (n > 0) {
                    root._brightnessMax = n;
                    root.brightnessAvailable = true;
                    brightnessGetProc.running = true;
                } else {
                    root.brightnessAvailable = false;
                }
            }
        }
    }

    property Process _brightnessGetProc: Process {
        id: brightnessGetProc
        command: ["sh", "-c", "brightnessctl g 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Number(text.trim());
                if (root._brightnessMax > 0 && n >= 0)
                    root.brightness = n / root._brightnessMax;
            }
        }
    }

    property Process _brightnessSetProc: Process {
        id: brightnessSetProc
    }

    function setBrightness(v) {
        const clamped = Math.max(0, Math.min(1, v));
        root.brightness = clamped; // optimistic; resynced by the next poll
        const pct = Math.round(clamped * 100);
        brightnessSetProc.command = ["sh", "-c", "brightnessctl set " + pct + "% 2>/dev/null"];
        brightnessSetProc.running = false;
        brightnessSetProc.running = true;
    }

    Component.onCompleted: {
        _cpuTempResolveProc.running = true;
        brightnessMaxProc.running = true;
    }
}
