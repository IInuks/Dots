pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Liest die live pywal-Palette (~/.cache/wal/colors.json), Quelle fuer das
// adaptive Blob-Theme (Settings.blobAdaptiveTheme, siehe BlobWindow.qml) --
// gleiche Quelle/gleiches Feld-Mapping wie bars/claude/Chroma.qml.
// shellwall aktualisiert die Datei bei jedem Wallpaper-Wechsel (`wal -i
// <path> -n -q`), unabhaengig davon, welche Shell laeuft -- reines
// Mitlesen, kein eigener pywal-Aufruf noetig.
QtObject {
    id: root

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
    // Standardfarben (Hintergrund "#221f30", Blob-Standardfarbe "#7c5cff"),
    // damit ein aktiviertes adaptives Theme ohne laufendes pywal optisch
    // nicht "kaputt" wirkt, sondern einfach wie der bisherige Look aussieht.
    property color background: root._fromWal ? root._fromWal.background : "#221f30"
    property color foreground: root._fromWal ? root._fromWal.foreground : "#f2f0fa"
    property color accent: root._fromWal ? root._fromWal.accent : "#7c5cff"

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
