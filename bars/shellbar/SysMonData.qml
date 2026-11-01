pragma Singleton
import QtQuick
import Quickshell.Io

// Shared system-monitor data: CPU/RAM/GPU/disk load, temps, uptime, plus a
// short rolling history for CPU/RAM/GPU so both SysMon's compact bar
// dropdown and the bigger chart-based Monitor tab in SettingsMenu read one
// live source instead of each polling /proc and nvidia-smi on its own.
QtObject {
    id: sysMonData

    readonly property int maxSamples: 40

    property real cpuPercent: 0
    property real ramPercent: 0
    property real ramUsedGB: 0
    property real ramTotalGB: 0
    property real gpuPercent: 0
    property real gpuTemp: 0
    property real cpuTemp: 0
    property bool gpuIsNvidia: true
    property real diskUsedGB: 0
    property real diskTotalGB: 0
    property real diskPercent: 0
    property string uptimeText: "—"

    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []

    property var _prevIdle: 0
    property var _prevTotal: 0
    property int _tick: 0
    property bool _gpuDetected: false

    // Whether nvidia-smi actually exists has to be resolved once up front:
    // Quickshell's Process neither fires `exited` nor its `onErrorOccurred`
    // hook when the binary itself is missing (only QProcess::FailedToStart,
    // which isn't wired to either), so gpuProc can't detect that on its own.
    Component.onCompleted: gpuDetectProc.running = true

    property var gpuDetectProc: Process {
        id: gpuDetectProc
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                sysMonData.gpuIsNvidia = text.trim() === "yes";
                sysMonData._gpuDetected = true;
            }
        }
    }

    function pushCpuHistory(v) {
        const arr = sysMonData.cpuHistory.concat([v]);
        if (arr.length > sysMonData.maxSamples) arr.splice(0, arr.length - sysMonData.maxSamples);
        sysMonData.cpuHistory = arr;
    }
    function pushRamHistory(v) {
        const arr = sysMonData.ramHistory.concat([v]);
        if (arr.length > sysMonData.maxSamples) arr.splice(0, arr.length - sysMonData.maxSamples);
        sysMonData.ramHistory = arr;
    }
    function pushGpuHistory(v) {
        const arr = sysMonData.gpuHistory.concat([v]);
        if (arr.length > sysMonData.maxSamples) arr.splice(0, arr.length - sysMonData.maxSamples);
        sysMonData.gpuHistory = arr;
    }

    // QtObject has no default property, so every poller below has to be
    // wired up via a `property var` assignment (same trick Theme.qml uses
    // for its FileView) instead of being a plain child item.
    property var pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            if (sysMonData._gpuDetected) {
                if (sysMonData.gpuIsNvidia) {
                    gpuProc.running = false;
                    gpuProc.running = true;
                } else {
                    amdGpuProc.running = false;
                    amdGpuProc.running = true;
                }
            }
            hwmonProc.running = false;
            hwmonProc.running = true;
            sysMonData._tick++;
            // Disk usage and uptime barely move second to second, so they
            // only need refreshing every 5th tick (10s) instead of every 2s.
            if (sysMonData._tick % 5 === 0) {
                diskProc.running = false;
                diskProc.running = true;
                uptimeFile.reload();
            }
        }
    }

    property var statFile: FileView {
        id: statFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const line = statFile.text().split("\n")[0];
            const parts = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + parts[4];
            const total = parts.reduce((a, b) => a + b, 0);
            const dIdle = idle - sysMonData._prevIdle;
            const dTotal = total - sysMonData._prevTotal;
            if (sysMonData._prevTotal > 0 && dTotal > 0) {
                sysMonData.cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal));
                sysMonData.pushCpuHistory(sysMonData.cpuPercent);
            }
            sysMonData._prevIdle = idle;
            sysMonData._prevTotal = total;
        }
    }

    property var memFile: FileView {
        id: memFile
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const text = memFile.text();
            const total = Number((/MemTotal:\s+(\d+)/.exec(text) || [0, 0])[1]);
            const avail = Number((/MemAvailable:\s+(\d+)/.exec(text) || [0, 0])[1]);
            if (total > 0) {
                sysMonData.ramPercent = 100 * (total - avail) / total;
                sysMonData.ramUsedGB = (total - avail) / 1048576;
                sysMonData.ramTotalGB = total / 1048576;
                sysMonData.pushRamHistory(sysMonData.ramPercent);
            }
        }
    }

    property var uptimeFile: FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const secs = Number(uptimeFile.text().split(" ")[0]);
            if (!isNaN(secs)) {
                const h = Math.floor(secs / 3600);
                const m = Math.floor((secs % 3600) / 60);
                sysMonData.uptimeText = h + "h " + m + "m";
            }
        }
    }

    property var gpuProc: Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",").map(s => Number(s.trim()));
                if (parts.length === 2 && !isNaN(parts[0])) {
                    sysMonData.gpuIsNvidia = true;
                    sysMonData.gpuPercent = parts[0];
                    sysMonData.gpuTemp = parts[1];
                    sysMonData.pushGpuHistory(sysMonData.gpuPercent);
                }
            }
        }
        // Safety net for when nvidia-smi exists but the query itself fails
        // (e.g. GPU in a bad state) -- the upfront detection in
        // gpuDetectProc is what actually handles the binary being absent.
        onExited: exitCode => {
            if (exitCode !== 0) {
                sysMonData.gpuIsNvidia = false;
                amdGpuProc.running = false;
                amdGpuProc.running = true;
            }
        }
    }

    property var amdGpuProc: Process {
        id: amdGpuProc
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = Number(text.trim());
                if (!isNaN(v)) {
                    sysMonData.gpuPercent = v;
                    sysMonData.pushGpuHistory(v);
                }
            }
        }
    }

    property var hwmonProc: Process {
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
                    if (!isNaN(millideg)) sysMonData.cpuTemp = millideg / 1000;
                }
                if (!sysMonData.gpuIsNvidia) {
                    const gpuHit = lines.find(l => l.startsWith("amdgpu:"));
                    if (gpuHit) {
                        const gpuMillideg = Number(gpuHit.split(":")[1]);
                        if (!isNaN(gpuMillideg)) sysMonData.gpuTemp = gpuMillideg / 1000;
                    }
                }
            }
        }
    }

    property var diskProc: Process {
        id: diskProc
        command: ["sh", "-c", "df -B1 / | tail -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 4) {
                    const total = Number(parts[1]);
                    const used = Number(parts[2]);
                    if (total > 0) {
                        sysMonData.diskTotalGB = total / 1073741824;
                        sysMonData.diskUsedGB = used / 1073741824;
                        sysMonData.diskPercent = 100 * used / total;
                    }
                }
            }
        }
    }
}
