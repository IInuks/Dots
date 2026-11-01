pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Aktuelles Wallpaper + seine Farben.
// awww kennt keine Events, also wird `awww query` alle 5 s gefragt (ein
// winziger Prozess, nur wenn sich der Pfad ändert passiert etwas). Die
// Farben liefert Quickshells ColorQuantizer (Median-Cut auf 64 px).
Singleton {
    id: root

    property string path: ""
    readonly property var colors: quant.colors
    readonly property bool ready: quant.colors.length > 0

    function refresh() {
        query.running = false;
        query.running = true;
    }

    Process {
        id: query
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /image:\s*(.+)$/m.exec(text);
                if (m && m[1].trim() !== root.path)
                    root.path = m[1].trim();
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    ColorQuantizer {
        id: quant
        source: root.path !== "" ? "file://" + root.path : ""
        depth: 4          // 16 Kandidaten
        rescaleSize: 64
    }
}
