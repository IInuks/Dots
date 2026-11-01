pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light through whichever of wlsunset / gammastep / hyprsunset is installed.
// None installed → available=false (tile shown disabled).
Singleton {
    id: root

    property string tool: ""
    readonly property bool available: tool !== ""
    readonly property bool active: proc.running
    property int temperature: 4000

    function toggle() {
        if (!available) return;
        if (proc.running) { proc.running = false; return; }
        proc.command = tool === "wlsunset" ? ["wlsunset", "-T", String(temperature + 1), "-t", String(temperature)]
                     : tool === "gammastep" ? ["gammastep", "-O", String(temperature)]
                     : ["hyprsunset", "-t", String(temperature)];
        proc.running = true;
    }

    Process { id: proc }

    Process {
        running: true
        command: ["sh", "-c", "for t in wlsunset gammastep hyprsunset; do command -v $t >/dev/null && { echo $t; break; }; done"]
        stdout: StdioCollector { onStreamFinished: root.tool = text.trim() }
    }
}
