pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness via brightnessctl -- no Quickshell-native brightness
// service exists (same conclusion bars/lucid/SystemService.qml already
// reached). `brightnessctl m` returning nothing/zero (no backlight
// device -- expected on this desktop's monitors, see memory
// user-system: NVIDIA desktop, no laptop panel) collapses `available` to
// false; ControlCenter.qml hides the slider entirely on that.
QtObject {
    id: root

    property bool available: false
    property real value: 0 // 0..1
    property int _max: 0

    property Process _maxProc: Process {
        command: ["sh", "-c", "brightnessctl m 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim(), 10);
                if (n > 0) {
                    root._max = n;
                    root.available = true;
                    _getProc.running = true;
                } else {
                    root.available = false;
                }
            }
        }
    }
    property Process _getProc: Process {
        command: ["sh", "-c", "brightnessctl g 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim(), 10);
                if (root._max > 0 && n >= 0) root.value = n / root._max;
            }
        }
    }
    property Process _setProc: Process {}

    function setValue(v) {
        const clamped = Math.max(0, Math.min(1, v));
        root.value = clamped; // optimistic; no poll loop to resync from here
        const pct = Math.round(clamped * 100);
        _setProc.command = ["sh", "-c", "brightnessctl set " + pct + "% 2>/dev/null"];
        _setProc.running = false;
        _setProc.running = true;
    }

    Component.onCompleted: _maxProc.running = true
}
