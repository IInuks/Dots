pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Aktuelles Wallpaper + seine Farben.
// awww kennt keine Events, also wird `awww query` alle 5 s gefragt (ein
// winziger Prozess, nur wenn sich der Pfad ändert passiert etwas). Die
// Farben liefert Quickshells ColorQuantizer (Median-Cut auf 64 px).
// Qt kann hier kein webp (qt6-imageformats fehlt): solche Bilder werden
// einmal per magick zu einem kleinen PNG in ~/.cache/drop umgewandelt.
Singleton {
    id: root

    property string path: ""
    property string source: ""      // was der Quantizer liest
    readonly property string _cache: Quickshell.env("HOME") + "/.cache/drop"
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

    onPathChanged: {
        if (path === "") { source = ""; return; }
        if (/\.(png|jpe?g|bmp)$/i.test(path)) { source = path; return; }
        const out = _cache + "/wall-" + Qt.md5(path) + ".png";
        convert.out = out;
        convert.command = ["sh", "-c", 'mkdir -p "$1" && { [ -s "$3" ] || magick "$2[0]" -resize 128x128 "png:$3"; }',
            "sh", _cache, path, out];
        convert.running = true;
    }
    Process {
        id: convert
        property string out: ""
        onExited: code => { if (code === 0) root.source = out; }
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
        source: root.source !== "" ? "file://" + root.source : ""
        depth: 4          // 16 Kandidaten
        rescaleSize: 64
    }
}
