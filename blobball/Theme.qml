pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Farben fuer das adaptive Blob-Theme (Settings.blobAdaptiveTheme, siehe
// BlobWindow.qml). Quelle ist das aktuelle Wallpaper selbst: awww kennt
// keine Events, also wird `awww query` alle 5 s gefragt; nur wenn sich der
// Pfad aendert, wertet Quickshells ColorQuantizer das Bild neu aus
// (gleiches Muster wie bars/drop/Wall.qml). Frueher kam die Farbe aus
// pywal (~/.cache/wal/colors.json) -- pywal ist aber gar nicht installiert,
// also stand der Blob immer auf der Standardfarbe. pywal bleibt nur noch
// Rueckfall, falls awww kein Bild meldet.
// Die errechnete Akzentfarbe wird nach ~/.cache/blobball/accent
// geschrieben, damit die Vorschau im quickdots-Menue (menu/BlobStore.qml)
// dieselbe Farbe zeigt.
QtObject {
    id: root

    // --- Wallpaper ---------------------------------------------------------
    property string wallPath: ""
    property string _quantSource: ""
    readonly property string _cacheDir: Quickshell.env("HOME") + "/.cache/blobball"

    property Process _query: Process {
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /image:\s*(.+)$/m.exec(text);
                const p = m ? m[1].trim() : "";
                if (p !== root.wallPath) root.wallPath = p;
            }
        }
    }
    property Timer _queryTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root._query.running = false; root._query.running = true; }
    }

    // Qt kann hier kein webp (qt6-imageformats fehlt): solche Bilder werden
    // einmal per magick zu einem kleinen PNG im Cache umgewandelt.
    onWallPathChanged: {
        if (wallPath === "") { _quantSource = ""; return; }
        if (/\.(png|jpe?g|bmp)$/i.test(wallPath)) { _quantSource = wallPath; return; }
        const out = _cacheDir + "/wall-" + Qt.md5(wallPath) + ".png";
        _convert.out = out;
        _convert.command = ["sh", "-c", 'mkdir -p "$1" && { [ -s "$3" ] || magick "$2[0]" -resize 128x128 "png:$3"; }',
            "sh", _cacheDir, wallPath, out];
        _convert.running = true;
    }
    property Process _convert: Process {
        property string out: ""
        onExited: code => { if (code === 0) root._quantSource = out; }
    }

    property ColorQuantizer _quant: ColorQuantizer {
        source: root._quantSource !== "" ? "file://" + root._quantSource : ""
        depth: 4          // 16 Kandidaten
        rescaleSize: 96
    }

    // Akzent: die farbigste Kachel, mittlere Helligkeit bevorzugt (sonst
    // gewinnen einzelne fast schwarze/weisse Sprenkel). Danach Saettigung und
    // Helligkeit in einen Bereich gezogen, in dem der Blob auf jedem
    // Hintergrund gut sichtbar bleibt. Fast graues Wallpaper -> neutrales Grau.
    readonly property var _wallAccent: {
        const sw = root._quant.colors ?? [];
        if (sw.length === 0) return null;
        let best = null, bs = 0.06;
        for (const c of sw) {
            if (c.hslHue < 0) continue;
            const sc = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.4);
            if (sc > bs) { bs = sc; best = c; }
        }
        if (!best) return Qt.hsla(0, 0, 0.68, 1);
        return Qt.hsla(best.hslHue,
                       Math.max(0.5, Math.min(0.85, best.hslSaturation)),
                       Math.max(0.5, Math.min(0.68, best.hslLightness)), 1);
    }

    // --- pywal (nur Rueckfall) --------------------------------------------
    property FileView _wal: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        printErrors: false
        watchChanges: true
        property var parsed: null
        onLoaded: {
            try {
                parsed = JSON.parse(text());
            } catch (e) {
                parsed = null;
            }
        }
        onLoadFailed: parsed = null
        onFileChanged: reload()
    }

    readonly property var _fromWal: {
        const w = root._wal.parsed;
        if (!w)
            return null;
        return {
            background: w.special.background,
            foreground: w.special.foreground,
            accent: w.colors.color4
        };
    }

    // Faellt auf dieselben Werte zurueck wie die bisherigen fest verdrahteten
    // Standardfarben (Hintergrund "#221f30", Blob-Standardfarbe "#7c5cff").
    property color background: root._fromWal ? root._fromWal.background : "#221f30"
    property color foreground: root._fromWal ? root._fromWal.foreground : "#f2f0fa"
    property color accent: root._wallAccent ?? (root._fromWal ? root._fromWal.accent : "#7c5cff")

    // Fuer die Menue-Vorschau (menu/BlobStore.qml liest die Datei).
    property FileView _accentOut: FileView {
        path: root._cacheDir + "/accent"
        printErrors: false
    }
    readonly property string _accentHex: root._wallAccent ? root._wallAccent.toString() : ""
    on_AccentHexChanged: if (_accentHex !== "") _accentWrite.restart()
    property Timer _accentWrite: Timer {
        interval: 300
        onTriggered: {
            root._mkdir.running = true;
        }
    }
    property Process _mkdir: Process {
        command: ["mkdir", "-p", root._cacheDir]
        onExited: root._accentOut.setText(root._accentHex + "\n")
    }

    // Nur fade, sobald die erste echte Palette ausgewertet wurde -- ohne
    // diese Sperre wuerde der allererste Paint von Schwarz ueberblenden
    // (gleiches Muster wie bars/claude/Chroma.qml).
    property bool _settled: false
    Component.onCompleted: _settleTimer.start()
    property Timer _settleTimer: Timer { interval: 50; onTriggered: root._settled = true }

    Behavior on background { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on foreground { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on accent { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }

    function _luminance(c) {
        const col = Qt.color(c);
        return 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;
    }

    // "auto" errechnet Schwarz/Weiss aus der Helligkeit von bg, "black"/
    // "white" (Settings.textColorMode) erzwingen eine feste Farbe --
    // gebraucht, weil ein adaptiver Hintergrund beliebig hell oder dunkel
    // sein kann und eine fest verdrahtete Textfarbe darauf unlesbar wuerde.
    function textColorFor(bg, mode) {
        if (mode === "black") return "#111111";
        if (mode === "white") return "#ffffff";
        return root._luminance(bg) < 0.5 ? "#ffffff" : "#111111";
    }
}
