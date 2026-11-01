import QtQuick
import Quickshell.Io

Item {
    id: root
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property real usage: 0
    property real _prevIdle: -1
    property real _prevTotal: -1

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.text
        font.pixelSize: 13
        text: Math.round(root.usage) + "%"
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: statProc
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
