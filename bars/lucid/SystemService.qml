pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU/RAM/disk polling plus brightness control -- the four System-panel
// metrics with no Quickshell-native service to read from directly (unlike
// volume/mic via Quickshell.Services.Pipewire, battery via Quickshell.
// Services.UPower, and WLAN/Bluetooth via Quickshell.Networking/Quickshell.
// Bluetooth, all of which the System panel's other rows read straight from
// -- see Panels/AudioSection.qml, BatteryRow.qml, WifiSection.qml,
// BluetoothSection.qml). Root-level singleton for the same cross-dir-import
// reason as Theme/Config/MangoService.
//
// CPU (/proc/stat delta) + RAM (/proc/meminfo) + disk (`df -B1 /`) reuse the
// exact approach already proven in bars/klasic/SystemStats.qml and
// bars/shellbar/SysMonData.qml -- disk only re-polled every 5th tick since
// it barely moves second to second, same as shellbar's.
//
// Brightness has no Quickshell service and no sibling bar in this repo has
// built it yet, so it's plain `brightnessctl` via Process: `m` for the max
// raw value, `g` for the current raw value, `set <pct>%` to change it.
// `brightnessctl m` returning nothing/zero (no backlight device, e.g. this
// dev machine when undocked) collapses brightnessAvailable to false --
// BrightnessRow.qml hides itself entirely on that, same present-gating
// bars/fisheye's BatteryModule already uses for "no battery".
QtObject {
    id: root

    property real cpuPercent: 0
    property real ramUsedGB: 0
    property real ramTotalGB: 0
    property real diskUsedGB: 0
    property real diskTotalGB: 0
    readonly property real ramPercent: root.ramTotalGB > 0 ? 100 * root.ramUsedGB / root.ramTotalGB : 0
    readonly property real diskPercent: root.diskTotalGB > 0 ? 100 * root.diskUsedGB / root.diskTotalGB : 0

    property bool brightnessAvailable: false
    property real brightness: 0 // 0..1
    property int _brightnessMax: 0

    property real _prevIdle: 0
    property real _prevTotal: 0
    property int _tick: 0

    property Timer _pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            root._tick++;
            if (root._tick % 5 === 0) {
                diskProc.running = false;
                diskProc.running = true;
            }
            if (root.brightnessAvailable) {
                brightnessGetProc.running = false;
                brightnessGetProc.running = true;
            }
        }
    }

    property FileView _statFile: FileView {
        id: statFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const line = statFile.text().split("\n")[0];
            const parts = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + parts[4];
            const total = parts.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._prevIdle;
            const dTotal = total - root._prevTotal;
            if (root._prevTotal > 0 && dTotal > 0)
                root.cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal));
            root._prevIdle = idle;
            root._prevTotal = total;
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
                root.ramUsedGB = (total - avail) / 1048576;
                root.ramTotalGB = total / 1048576;
            }
        }
    }

    property Process _diskProc: Process {
        id: diskProc
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
                    }
                }
            }
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

    Component.onCompleted: brightnessMaxProc.running = true
}
