pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lautstaerke ueber wpctl statt Quickshell.Services.Pipewire: die Bar kann
// beim Login vor PipeWire starten, und wpctl/pactl lassen sich einfach
// erneut versuchen. `pactl subscribe` meldet Aenderungen, dann wird neu
// gelesen.
Singleton {
    id: root

    property real volume: 0
    property bool muted: false
    property bool available: false

    readonly property string sink: "@DEFAULT_AUDIO_SINK@"

    function refresh() {
        query.running = false;
        query.running = true;
    }
    function step(dir) {
        const pct = Math.round(Config.volumeStep * 100) + "%" + (dir > 0 ? "+" : "-");
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", sink, pct]);
        later.restart();
    }
    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", sink, "toggle"]);
        later.restart();
    }

    property Process query: Process {
        command: ["wpctl", "get-volume", root.sink]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s*([\d.]+)/);
                root.available = !!m;
                if (m) {
                    root.volume = parseFloat(m[1]);
                    root.muted = text.indexOf("MUTED") !== -1;
                }
            }
        }
    }
    property Timer later: Timer {
        interval: 90
        onTriggered: root.refresh()
    }
    property Process events: Process {
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("sink") !== -1 || line.indexOf("server") !== -1)
                    root.later.restart();
            }
        }
        onExited: root.retry.restart()
    }
    property Timer retry: Timer {
        interval: 3000
        onTriggered: {
            root.refresh();
            root.events.running = true;
        }
    }
}
