pragma Singleton
import QtQuick
import Quickshell.Io

// Shared system-monitor data for the Command Center's System tab: CPU/RAM/
// GPU load + temps, disk, uptime, network throughput, plus rolling history
// for the chart cards. Polled once here so the tab itself stays cheap to
// open/close.
QtObject {
    id: root

    readonly property int maxSamples: 40

    property real cpuPercent: 0
    property real cpuTemp: 0
    property real ramPercent: 0
    property real ramUsedGB: 0
    property real ramTotalGB: 0
    property real gpuPercent: 0
    property real gpuTemp: 0
    property bool gpuIsNvidia: false
    property real diskUsedGB: 0
    property real diskTotalGB: 0
    property real diskPercent: 0
    property string uptimeText: "—"
    property real netRxKBs: 0
    property real netTxKBs: 0

    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []

    property real _prevIdle: -1
    property real _prevTotal: -1
    property real _prevRx: -1
    property real _prevTx: -1
    property int _tick: 0

    function _push(arr, v) {
        const out = arr.concat([v]);
        if (out.length > root.maxSamples) out.splice(0, out.length - root.maxSamples);
        return out;
    }

    property Timer _pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _cpuProc.running = false; _cpuProc.running = true;
            _memProc.running = false; _memProc.running = true;
            _netProc.running = false; _netProc.running = true;
            _gpuProc.running = false; _gpuProc.running = true;
            _hwmonProc.running = false; _hwmonProc.running = true;
            root._tick++;
            if (root._tick % 5 === 0) {
                _diskProc.running = false; _diskProc.running = true;
                _uptimeProc.running = false; _uptimeProc.running = true;
            }
        }
    }

    property Process _cpuProc: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n")[0];
                const parts = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = parts[3] + parts[4];
                const total = parts.reduce((a, b) => a + b, 0);
                if (root._prevTotal >= 0) {
                    const dIdle = idle - root._prevIdle;
                    const dTotal = total - root._prevTotal;
                    if (dTotal > 0) {
                        root.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal)));
                        root.cpuHistory = root._push(root.cpuHistory, root.cpuPercent);
                    }
                }
                root._prevIdle = idle;
                root._prevTotal = total;
            }
        }
    }

    property Process _memProc: Process {
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let total = 0, avail = 0;
                for (const l of lines) {
                    const m = l.match(/(\d+)/);
                    if (!m) continue;
                    if (l.startsWith("MemTotal")) total = Number(m[1]);
                    else if (l.startsWith("MemAvailable")) avail = Number(m[1]);
                }
                if (total > 0) {
                    root.ramPercent = 100 * (total - avail) / total;
                    root.ramUsedGB = (total - avail) / 1048576;
                    root.ramTotalGB = total / 1048576;
                    root.ramHistory = root._push(root.ramHistory, root.ramPercent);
                }
            }
        }
    }

    // Sums every non-loopback interface rather than guessing a name, so it
    // keeps working across wifi/ethernet/USB-tether swaps.
    property Process _netProc: Process {
        command: ["sh", "-c", "awk 'NR>2 && $1!~/^lo:/ {gsub(\":\",\"\",$1); rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).map(Number);
                if (parts.length === 2 && !isNaN(parts[0])) {
                    if (root._prevRx >= 0) {
                        root.netRxKBs = Math.max(0, (parts[0] - root._prevRx) / 1024 / 2);
                        root.netTxKBs = Math.max(0, (parts[1] - root._prevTx) / 1024 / 2);
                    }
                    root._prevRx = parts[0];
                    root._prevTx = parts[1];
                }
            }
        }
    }

    property Process _gpuProc: Process {
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",").map(s => Number(s.trim()));
                if (parts.length === 2 && !isNaN(parts[0])) {
                    root.gpuIsNvidia = true;
                    root.gpuPercent = parts[0];
                    root.gpuTemp = parts[1];
                    root.gpuHistory = root._push(root.gpuHistory, root.gpuPercent);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.gpuIsNvidia = false;
                _amdGpuProc.running = false;
                _amdGpuProc.running = true;
            }
        }
    }

    property Process _amdGpuProc: Process {
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = Number(text.trim());
                if (!isNaN(v)) {
                    root.gpuPercent = v;
                    root.gpuHistory = root._push(root.gpuHistory, v);
                }
            }
        }
    }

    property Process _hwmonProc: Process {
        command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp1_input; do n=$(cat \"$(dirname \"$f\")/name\" 2>/dev/null); t=$(cat \"$f\" 2>/dev/null); echo \"$n:$t\"; done 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const cpuPriority = ["k10temp", "coretemp", "zenpower", "cpu_thermal"];
                const gpuPriority = ["amdgpu", "radeon"];
                let cpuPicked = null, gpuPicked = null;
                for (const name of cpuPriority) {
                    const hit = lines.find(l => l.startsWith(name + ":"));
                    if (hit) { cpuPicked = hit; break; }
                }
                if (!cpuPicked && lines.length > 0) cpuPicked = lines[0];
                for (const name of gpuPriority) {
                    const hit = lines.find(l => l.startsWith(name + ":"));
                    if (hit) { gpuPicked = hit; break; }
                }
                if (cpuPicked) {
                    const m = Number(cpuPicked.split(":")[1]);
                    if (!isNaN(m)) root.cpuTemp = m / 1000;
                }
                if (gpuPicked && !root.gpuIsNvidia) {
                    const m = Number(gpuPicked.split(":")[1]);
                    if (!isNaN(m)) root.gpuTemp = m / 1000;
                }
            }
        }
    }

    property Process _diskProc: Process {
        command: ["sh", "-c", "df -B1 / | tail -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 4) {
                    const total = Number(parts[1]);
                    const used = Number(parts[2]);
                    if (total > 0) {
                        root.diskTotalGB = total / 1073741824;
                        root.diskUsedGB = used / 1073741824;
                        root.diskPercent = 100 * used / total;
                    }
                }
            }
        }
    }

    property Process _uptimeProc: Process {
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const secs = Number(text.trim().split(" ")[0]);
                if (!isNaN(secs)) {
                    const h = Math.floor(secs / 3600);
                    const m = Math.floor((secs % 3600) / 60);
                    root.uptimeText = h + "h " + m + "m";
                }
            }
        }
    }
}
