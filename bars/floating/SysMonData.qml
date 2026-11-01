pragma Singleton
import QtQuick
import Quickshell.Io

// System-monitor data, ported from shellbar/SysMonData.qml (CPU/RAM/GPU/disk
// /uptime, same /proc + hwmon approach, already proven on this machine) plus
// two additions the spec asks for that no existing bar has: network
// up/down rate and top-5 processes by CPU.
//
// cpuTemp polls continuously at a slow (3s) cadence, per spec 4
// "System-Monitor": the bar's own temperature readout stays live even with
// the popup closed. Everything else only polls (at 1.5s) while
// `detailActive` is true -- the System-Monitor popup sets that itself via
// Component.onCompleted/onDestruction, so the heavier polling (ps, GPU
// query, disk, network) only runs while its popup is actually open.
QtObject {
    id: sysMonData

    readonly property int maxSamples: 40
    property bool detailActive: false

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
    property real networkUpKBs: 0
    property real networkDownKBs: 0
    property var topProcesses: [] // [{pid, name, cpu}]

    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []

    property var _prevIdle: 0
    property var _prevTotal: 0
    property var _prevRxBytes: -1
    property var _prevTxBytes: -1
    property int _tick: 0

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

    // -- always-on: CPU temperature, per spec ("Temperatur in der Bar seltener") --

    property var tempTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { hwmonProc.running = false; hwmonProc.running = true; }
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
            }
        }
    }

    // -- detail polling: only while the System-Monitor popup is open --

    property var pollTimer: Timer {
        interval: 1500
        running: sysMonData.detailActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            gpuProc.running = false;
            gpuProc.running = true;
            netFile.reload();
            processesProc.running = false;
            processesProc.running = true;
            sysMonData._tick++;
            if (sysMonData._tick % 4 === 0) {
                diskProc.running = false;
                diskProc.running = true;
                uptimeFile.reload();
            }
        }
    }
    onDetailActiveChanged: {
        // Fresh baseline each time the popup (re)opens, otherwise the first
        // network-rate sample after a gap would show a huge spurious spike.
        if (sysMonData.detailActive) {
            sysMonData._prevRxBytes = -1;
            sysMonData._prevTxBytes = -1;
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

    // -- network rate: diff cumulative rx/tx bytes across the same poll
    // interval as everything else, same delta idiom as the CPU-percent
    // calculation above. Sums every non-loopback interface. --

    property var netFile: FileView {
        id: netFile
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: {
            const lines = netFile.text().split("\n").slice(2);
            let rx = 0, tx = 0;
            for (const line of lines) {
                const t = line.trim();
                if (!t) continue;
                const [iface, rest] = t.split(":");
                if (!rest || iface.trim() === "lo") continue;
                const fields = rest.trim().split(/\s+/).map(Number);
                rx += fields[0] || 0;
                tx += fields[8] || 0;
            }
            if (sysMonData._prevRxBytes >= 0) {
                const dt = sysMonData.pollTimer.interval / 1000;
                sysMonData.networkDownKBs = Math.max(0, (rx - sysMonData._prevRxBytes) / 1024 / dt);
                sysMonData.networkUpKBs = Math.max(0, (tx - sysMonData._prevTxBytes) / 1024 / dt);
            }
            sysMonData._prevRxBytes = rx;
            sysMonData._prevTxBytes = tx;
        }
    }

    // -- top 5 processes by CPU --

    property var processesProc: Process {
        id: processesProc
        command: ["sh", "-c", "ps -eo pid,comm,%cpu --sort=-%cpu --no-headers | head -n 5"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                sysMonData.topProcesses = lines.map(line => {
                    const t = line.trim();
                    const firstSpace = t.indexOf(" ");
                    const lastSpace = t.lastIndexOf(" ");
                    const pid = t.slice(0, firstSpace);
                    const name = t.slice(firstSpace + 1, lastSpace).trim();
                    const cpu = Number(t.slice(lastSpace + 1));
                    return { pid: pid, name: name, cpu: isNaN(cpu) ? 0 : cpu };
                });
            }
        }
    }
}
