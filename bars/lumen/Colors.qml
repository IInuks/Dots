pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Root-Singleton: bewusst nicht in einem Config/-Unterordner, weil ein
// pragma-Singleton in dieser Quickshell-Version nur ueber denselben Ordner
// oder eine reine "..".."-Elternkette zuverlaessig aufloest. Ein seitlicher
// Import (z.B. aus Modules/Bar/ nach Config/) liefert sonst kommentarlos
// ein Objekt, dessen Properties alle undefined sind -- ohne Fehlermeldung.
// Module erreichen diese Datei daher per "import "../.."".
//
// Adaptiv per pywal: liest ~/.cache/wal/colors.json, das Wallpaper.qml bei
// jedem Wallpaper-Wechsel per `wal -i <pfad> -n -q` neu schreibt (gleiche
// Kette wie shellwall/simple). watchChanges triggert einen Reload sobald
// die Datei sich aendert -- kein Bar-Neustart noetig. Fehlt die Datei
// (frisches System, wal nie gelaufen), greift die Fallback-Palette unten:
// warmes Amber/Bernstein statt der pinken Palette von "simple", damit
// "lumen" auch ohne pywal-Lauf eine eigene Identitaet hat.
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

    readonly property bool _hasWal: root._wal.parsed !== null

    // Fallback-Palette: warmes, dunkles Amber/Bernstein -- "lumen" = Licht.
    readonly property color _fallbackBg: "#181410"
    readonly property color _fallbackText: "#f0e6d2"
    readonly property color _fallbackAccent: "#ffb84d"
    readonly property color _fallbackAccentAlt: "#7fd9c4"

    readonly property color _rawBg: root._hasWal ? root._wal.parsed.special.background : root._fallbackBg
    readonly property color _rawText: root._hasWal ? root._wal.parsed.special.foreground : root._fallbackText
    readonly property color _rawAccent: root._hasWal ? root._wal.parsed.colors.color1 : root._fallbackAccent
    readonly property color _rawAccentAlt: root._hasWal ? root._wal.parsed.colors.color2 : root._fallbackAccentAlt

    function _luminance(c) {
        const col = Qt.color(c);
        return 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;
    }

    function _mix(a, b, t) {
        const ca = Qt.color(a), cb = Qt.color(b);
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1);
    }

    function _contrastOn(c) {
        return root._luminance(c) > 0.6 ? Qt.rgba(0.08, 0.08, 0.09, 1) : Qt.rgba(0.98, 0.97, 0.94, 1);
    }

    // Nicht readonly (siehe Behaviors unten) -- Bindung an die _raw*-Werte
    // haelt sie trotzdem immer synchron mit der aktuellen Palette.
    property color bg: root._rawBg
    property color panel: root._mix(root._rawBg, root._rawText, 0.09)
    property color panelAlt: root._mix(root._rawBg, root._rawText, 0.16)

    property color text: root._rawText
    property color textDim: root._mix(root._rawText, root._rawBg, 0.45)

    property color accent: root._rawAccent
    property color accentAlt: root._rawAccentAlt
    // "onAccent" wuerde QML als Signal-Handler parsen ("Cannot assign a
    // value to a signal") -- deshalb accentInk, nicht onAccent.
    property color accentInk: root._contrastOn(root._rawAccent)

    property color divider: root._mix(root._rawBg, root._rawText, 0.16)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property real letterSpacing: 0.4

    // Sanfter Crossfade bei Wallpaper-/Palettenwechsel statt hartem Sprung.
    Behavior on bg {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on panel {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on panelAlt {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on text {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on textDim {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on accent {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on accentAlt {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on accentInk {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on divider {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
}
