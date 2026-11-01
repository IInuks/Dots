pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// "Slate & Verdigris": cool graphite ink with a teal/gold accent pair.
// Three sources feed `active`: two fixed palettes (dark/light) and a live
// one read from pywal's colors.json (shellwall already regenerates that
// file on every wallpaper change via `wal -i <path> -n -q`, regardless of
// which shell is running -- reading it here is just consuming that
// system-wide convention, not tied to any particular bar).
//
// Named "Chroma" rather than the obvious "Palette" -- that name silently
// shadows a Qt/QtQuick builtin type wherever `import QtQuick`/`import
// Quickshell` is present: the singleton still registers without error, but
// every property on it reads back as undefined everywhere it's used, with
// no exception or failed-load message anywhere in the logs. Confirmed by
// bisecting a minimal reproduction down to just the filename.
QtObject {
    id: root

    readonly property var _dark: ({
        ink: "#12151a",
        panel: "#1b2027",
        panelRaised: "#242b34",
        text: "#eef1f4",
        textFaint: "#8b95a1",
        accent: "#4fd8c4",
        accent2: "#f2b84b",
        bad: "#ff6b6b",
        good: "#6bcf8f"
    })

    readonly property var _light: ({
        ink: "#f3f5f7",
        panel: "#ffffff",
        panelRaised: "#e7ebef",
        text: "#171b20",
        textFaint: "#6b7480",
        accent: "#12897d",
        accent2: "#b9860a",
        bad: "#d6314f",
        good: "#1f9d63"
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
            panel: dark ? Qt.lighter(bg, 1.28) : Qt.darker(bg, 1.06),
            panelRaised: dark ? Qt.lighter(bg, 1.55) : Qt.darker(bg, 1.12),
            text: fg,
            textFaint: dark ? Qt.darker(fg, 1.6) : Qt.lighter(fg, 1.6),
            accent: w.colors.color4,
            accent2: w.colors.color3,
            bad: w.colors.color1,
            good: w.colors.color2
        };
    }

    readonly property var active: {
        if (Config.mode === "light")
            return root._light;
        if (Config.mode === "adaptive" && root._fromWal)
            return root._fromWal;
        return root._dark;
    }

    property color ink: active.ink
    property color panel: active.panel
    property color panelRaised: active.panelRaised
    property color text: active.text
    property color textFaint: active.textFaint
    property color accent: active.accent
    property color accent2: active.accent2
    property color bad: active.bad
    property color good: active.good

    // Only fade once the first real palette has been evaluated -- without
    // this guard the very first paint crossfades in from black.
    property bool _settled: false
    Component.onCompleted: _settleTimer.start()
    property Timer _settleTimer: Timer { interval: 50; onTriggered: root._settled = true }

    Behavior on ink { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on panel { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on panelRaised { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on text { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on textFaint { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on accent { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on accent2 { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on bad { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }
    Behavior on good { enabled: root._settled; ColorAnimation { duration: 420; easing.type: Easing.InOutQuad } }

    readonly property real barAlpha: Config.barAlpha
    readonly property int rSmall: 7
    readonly property int rMed: 14
    readonly property int rBar: 18
    readonly property int tFast: 140
    readonly property int tMed: 260
    readonly property int tSlow: 440
}
