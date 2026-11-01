pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight brightness via brightnessctl, falling back to ddcutil (external monitors).
// If neither works the module reports available=false and the UI hides it.
Singleton {
    id: root

    property string backend: ""          // "brightnessctl" | "ddcutil" | ""
    readonly property bool available: backend !== ""
    property real value: 0               // 0..1
    property int _max: 100

    function set(v) {
        if (!available) return;
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        pending = Math.round(v * 100);
        apply.restart();
    }
    function step(delta) { set(value + delta); }

    property int pending: -1
    // throttle writes (ddcutil is slow)
    Timer {
        id: apply
        interval: root.backend === "ddcutil" ? 250 : 30
        onTriggered: {
            if (root.pending < 0) return;
            Quickshell.execDetached(root.backend === "ddcutil"
                ? ["ddcutil", "--noverify", "setvcp", "10", String(root.pending)]
                : ["brightnessctl", "-q", "set", root.pending + "%"]);
            root.pending = -1;
        }
    }

    // probe: brightnessctl needs a backlight device; ddcutil needs a DDC/CI monitor
    Process {
        running: true
        command: ["sh", "-c",
            "if command -v brightnessctl >/dev/null && [ -n \"$(ls /sys/class/backlight 2>/dev/null)\" ]; then " +
            "echo brightnessctl $(brightnessctl -m | cut -d, -f4 | tr -d %); " +
            "elif command -v ddcutil >/dev/null; then v=$(ddcutil -t getvcp 10 2>/dev/null) && echo ddcutil $(echo \"$v\" | awk '{print int($4*100/$5)}'); fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length === 2 && !isNaN(parseInt(parts[1]))) {
                    root.backend = parts[0];
                    root.value = parseInt(parts[1]) / 100;
                }
            }
        }
    }
}
