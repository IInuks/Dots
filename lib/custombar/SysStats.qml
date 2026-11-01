pragma Singleton
import QtQuick
import Quickshell.Io

// CPU load percentage from /proc/stat deltas, shared by every CpuModule
// instance instead of each polling its own Process. Same technique as
// bars/quickbar/CpuUsage.qml. Lives directly in lib/custombar/ (not a
// services/ subfolder) so modules/*.qml can reach it via a plain
// `import ".."` -- singletons resolve correctly across a same-directory or
// direct-parent relative import, but silently return a broken, all-fields-
// undefined proxy across any sideways import (sibling dir, symlinked child,
// etc., with or without `as NS`) in this Quickshell version. Confirmed by
// direct testing; see the memory note on this.
QtObject {
    id: root

    property real usage: 0
    property real _prevIdle: -1
    property real _prevTotal: -1

    // QtObject has no default property -- a bare `Timer { ... }` child here
    // fails with "Cannot assign to non-existent default property" (only
    // Item-derived types can take unwrapped children), so every non-visual
    // child must be attached via a named property instead.
    property Timer _timer: Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: _proc.running = true
    }

    property Process _proc: Process {
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
                    if (dTotal > 0) root.usage = 100 * (1 - dIdle / dTotal);
                }
                root._prevIdle = idle;
                root._prevTotal = total;
            }
        }
    }
}
