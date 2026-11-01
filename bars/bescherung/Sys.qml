pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU- und RAM-Auslastung aus /proc, alle Config.statsInterval ms.
Singleton {
    id: root

    property real cpu: 0
    property real mem: 0
    property var _last: null

    function _parse(text) {
        let total = 0, idle = 0, memTotal = 0, memAvail = 0;
        for (const line of text.split("\n")) {
            if (line.startsWith("cpu ")) {
                const v = line.trim().split(/\s+/).slice(1).map(Number);
                total = v.slice(0, 8).reduce((a, b) => a + b, 0);
                idle = v[3] + v[4];
            } else if (line.startsWith("MemTotal:")) {
                memTotal = parseInt(line.split(/\s+/)[1]);
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = parseInt(line.split(/\s+/)[1]);
            }
        }
        if (_last && total > _last.total)
            cpu = 1 - (idle - _last.idle) / (total - _last.total);
        _last = { total: total, idle: idle };
        if (memTotal > 0)
            mem = 1 - memAvail / memTotal;
    }

    property Process reader: Process {
        command: ["cat", "/proc/stat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }
    property Timer tick: Timer {
        interval: Config.statsInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reader.running = true
    }
}
