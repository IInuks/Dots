pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio spectrum from cava (raw ASCII, 72 bars, mono). cava only runs while the
// default sink is actually audible: a cheap PipeWire peak monitor wakes it up,
// and it is stopped again after a few seconds of silence.
Singleton {
    id: root

    property bool installed: false
    property bool wanted: true            // false when the visualizer is switched off
    property var values: []               // 0..1, low → high frequency
    readonly property bool active: cava.running
    property double _lastLoud: 0

    PwNodePeakMonitor {
        id: peaks
        node: Pipewire.defaultAudioSink
        enabled: root.installed && root.wanted
        onPeakChanged: {
            if (peak > 0.002) {
                root._lastLoud = Date.now();
                if (!cava.running) cava.running = true;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: cava.running
        onTriggered: {
            if (!root.wanted || Date.now() - root._lastLoud > 3000) {
                cava.running = false;
                root.values = [];
            }
        }
    }

    Process {
        id: cava
        command: ["cava", "-p", Quickshell.shellDir + "/assets/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = new Array(parts.length - 1);
                for (let i = 0; i < out.length; i++) out[i] = (parseInt(parts[i]) || 0) / 1000;
                root.values = out;
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: code => root.installed = code === 0
    }
}
