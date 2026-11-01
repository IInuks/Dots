import QtQuick
import Quickshell.Io
import ".."

// CPU load gauge: samples the aggregate "cpu " line from /proc/stat every
// 2s and turns the deltas between two samples into a load fraction. Click
// opens the in-shell system monitor flyout directly above this icon.
Meter {
    id: root
    glyphName: "cpu"
    ringColor: value > 0.85 ? Chroma.bad : Chroma.accent

    onClicked: {
        const center = root.mapToItem(null, root.width / 2, 0);
        Popups.toggleAt("monitor", center.x);
    }

    property var _prevTotals: null

    function _parse(line) {
        const parts = line.trim().split(/\s+/).slice(1).map(Number);
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);
        return { idle, total };
    }

    Process {
        id: proc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = root._parse(text);
                if (root._prevTotals) {
                    const dTotal = cur.total - root._prevTotals.total;
                    const dIdle = cur.idle - root._prevTotals.idle;
                    if (dTotal > 0)
                        root.value = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
                }
                root._prevTotals = cur;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { proc.running = false; proc.running = true; }
    }
}
