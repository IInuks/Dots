pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Named "Theme" rather than "Palette"/"Colors"/"Layout" -- those names
// silently shadow Qt/QtQuick or Quickshell builtins wherever `import
// QtQuick`/`import Quickshell` is present: the singleton still registers,
// but every property on it then reads back as undefined everywhere, with
// no error anywhere in the logs (see bars/claude/README.md "Bug-Fundstuecke").
//
// Four sources feed `active`:
//   dark / light   -- fixed palettes
//   adaptive       -- live from pywal's colors.json (shellwall reruns
//                      `wal -i <path> -n -q` on every wallpaper change)
//   auto           -- switches between the fixed dark/light palettes by
//                      time of day (Config.autoLightStart/End), independent
//                      of the wallpaper -- this is the mode none of the
//                      sibling bars have
QtObject {
    id: root

    readonly property var _dark: ({
        ink: "#14161c",
        panel: "#1d2029",
        panelRaised: "#272b36",
        text: "#eceef2",
        textFaint: "#8a90a0",
        accent: "#7aa2f7",
        bad: "#f7768e",
        good: "#9ece6a"
    })

    readonly property var _light: ({
        ink: "#f4f5f7",
        panel: "#ffffff",
        panelRaised: "#e8eaef",
        text: "#191c22",
        textFaint: "#666e7d",
        accent: "#3a5ccc",
        bad: "#c4314f",
        good: "#1f8a4c"
    })

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

    function _luminance(hex) {
        const c = Qt.color(hex);
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    readonly property var _fromWal: {
        const w = root._wal.parsed;
        if (!w)
            return null;
        const bg = w.special.background;
        const fg = w.special.foreground;
        const dark = root._luminance(bg) < 0.5;
        return {
            ink: bg,
            panel: dark ? Qt.lighter(bg, 1.25) : Qt.darker(bg, 1.05),
            panelRaised: dark ? Qt.lighter(bg, 1.5) : Qt.darker(bg, 1.1),
            text: fg,
            textFaint: dark ? Qt.darker(fg, 1.6) : Qt.lighter(fg, 1.6),
            accent: w.colors.color4,
            bad: w.colors.color1,
            good: w.colors.color2
        };
    }

    // Recomputed every minute so a screen left open crosses the
    // light/dark boundary on its own, no restart needed.
    property int _clockMinute: 0
    property Timer _clockTimer: Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._clockMinute = new Date().getMinutes()
    }

    readonly property bool _autoIsLight: {
        _clockMinute; // dependency: re-evaluate every tick
        const h = new Date().getHours();
        const start = Config.autoLightStart;
        const end = Config.autoLightEnd;
        return start <= end ? (h >= start && h < end) : (h >= start || h < end);
    }

    readonly property var active: {
        if (Config.mode === "light")
            return root._light;
        if (Config.mode === "auto")
            return root._autoIsLight ? root._light : root._dark;
        if (Config.mode === "adaptive" && root._fromWal)
            return root._fromWal;
        return root._dark;
    }

    property color ink: active.ink
    property color panel: active.panel
    property color panelRaised: active.panelRaised
    property color text: active.text
    property color textFaint: active.textFaint
    property color accent: Config.accentOverride.length > 0 ? Config.accentOverride : active.accent
    property color bad: active.bad
    property color good: active.good

    // Only fade once the first real palette has settled -- otherwise the
    // very first paint crossfades in from black.
    property bool _settled: false
    Component.onCompleted: _settleTimer.start()
    property Timer _settleTimer: Timer { interval: 50; onTriggered: root._settled = true }

    Behavior on ink { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on panel { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on panelRaised { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on text { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on textFaint { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on accent { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on bad { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    Behavior on good { enabled: root._settled; ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }

    readonly property real barAlpha: Config.barAlpha
    readonly property int rSmall: 8
    readonly property int rMed: 14
    readonly property int rBar: 16
    readonly property int tFast: 130
    readonly property int tMed: 240
    readonly property int tSlow: 420

    readonly property var accentSwatches: ["#7aa2f7", "#f7768e", "#9ece6a", "#e0af68", "#bb9af7", "#7dcfff"]
}
