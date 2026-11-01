pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System telemetry for the Telemetry flyout: CPU load (delta of /proc/stat
// jiffies between polls), memory usage (/proc/meminfo), uptime
// (/proc/uptime). Each stat is its own tiny one-shot `cat` process re-run
// every 2s via the same exit-then-restart Timer pattern MangoIpc.qml uses
// for its `mmsg watch` processes -- here it's the polling mechanism itself
// rather than crash recovery, since `cat` always exits right away.
QtObject {
    id: root

    property real cpuPercent: 0
    property real memPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real uptimeSeconds: 0
    property string hostname: ""
    property string kernel: ""

    property real _prevTotal: -1
    property real _prevIdle: -1
    property real _memTotalKb: -1
    property real _memAvailKb: -1

    property Process _statProc: Process {
        running: true
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: line => {
                if (!line.startsWith("cpu "))
                    return;
                const fields = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = (fields[3] || 0) + (fields[4] || 0);
                const total = fields.reduce((a, b) => a + b, 0);
                if (root._prevTotal >= 0) {
                    const dTotal = total - root._prevTotal;
                    const dIdle = idle - root._prevIdle;
                    if (dTotal > 0)
                        root.cpuPercent = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
                }
                root._prevTotal = total;
                root._prevIdle = idle;
            }
        }
        onExited: _statRestart.start()
    }
    property Timer _statRestart: Timer { interval: 2000; onTriggered: { _statProc.running = false; _statProc.running = true; } }

    property Process _memProc: Process {
        running: true
        command: ["cat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("MemTotal:"))
                    root._memTotalKb = parseFloat(line.replace(/[^0-9.]/g, ""));
                else if (line.startsWith("MemAvailable:"))
                    root._memAvailKb = parseFloat(line.replace(/[^0-9.]/g, ""));
                if (root._memTotalKb >= 0 && root._memAvailKb >= 0) {
                    root.memPercent = Math.max(0, Math.min(1, 1 - root._memAvailKb / root._memTotalKb));
                    root.memTotalGiB = root._memTotalKb / (1024 * 1024);
                    root.memUsedGiB = (root._memTotalKb - root._memAvailKb) / (1024 * 1024);
                }
            }
        }
        onExited: _memRestart.start()
    }
    property Timer _memRestart: Timer {
        interval: 2000
        onTriggered: { root._memTotalKb = -1; root._memAvailKb = -1; _memProc.running = false; _memProc.running = true; }
    }

    property Process _uptimeProc: Process {
        running: true
        command: ["cat", "/proc/uptime"]
        stdout: SplitParser {
            onRead: line => { root.uptimeSeconds = parseFloat(line.trim().split(/\s+/)[0]) || 0; }
        }
        onExited: _uptimeRestart.start()
    }
    property Timer _uptimeRestart: Timer { interval: 1000; onTriggered: { _uptimeProc.running = false; _uptimeProc.running = true; } }

    property Process _identProc: Process {
        running: true
        command: ["sh", "-c", "hostname; uname -sr"]
        stdout: SplitParser {
            property int _n: 0
            onRead: line => {
                if (_n === 0)
                    root.hostname = line.trim();
                else if (_n === 1)
                    root.kernel = line.trim();
                _n++;
            }
        }
    }
}
