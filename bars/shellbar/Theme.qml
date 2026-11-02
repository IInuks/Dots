pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Central theme singleton. Holds color presets + shared geometry constants
// (bar height, liquid-menu radii) so every module and LiquidMenu instance
// stays in sync when the preset is switched live.
QtObject {
    id: theme

    // Live wallpaper palette for the "Adaptive" preset below. shellwall runs
    // matugen and writes Material You roles to ricev2/colors.json. Keep the
    // file watcher for immediate updates, with a periodic reload as a fallback
    // when the writer replaces the file and the watcher loses track of it.
    property var wal: FileView {
        id: wal
        path: Quickshell.env("HOME") + "/.cache/ricev2/colors.json"
        printErrors: false
        watchChanges: true
        property var parsed: null
        onLoaded: {
            try {
                parsed = JSON.parse(wal.text());
            } catch (e) {
                parsed = null;
            }
        }
        onFileChanged: reload()
    }

    property Timer reloadTimer: Timer {
        interval: 1500
        repeat: true
        running: theme.presetKey === "adaptive" && !theme.useCustomColors
        onTriggered: wal.reload()
    }

    function relLuminance(hex) {
        const c = Qt.color(hex);
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    readonly property color adaptiveSurface: wal.parsed ? (wal.parsed.surface || wal.parsed.background) : "#1c1c26"
    readonly property color adaptiveForeground: wal.parsed ? (wal.parsed.surfaceText || wal.parsed.backgroundText) : "#e8e8f0"
    readonly property color adaptiveMutedText: wal.parsed ? wal.parsed.outline : "#8d8da0"
    readonly property color adaptiveAccent: wal.parsed ? wal.parsed.primary : "#5b8cff"
    readonly property color adaptiveUrgent: wal.parsed ? wal.parsed.error : "#ff5c66"

    // Keep only labels in this map. Palette colors are resolved by functions
    // below so bindings read the current adaptive palette every time; values
    // embedded in a JavaScript object literal would be captured only once.
    readonly property var presets: ({
        adaptive: { label: "Adaptive" },
        mono: { label: "Mono" },
        monoInvert: { label: "Mono Invert" }
    })

    readonly property var presetOrder: ["adaptive", "mono", "monoInvert"]

    property string presetKey: "mono"

    // -- custom colors (Design tab's opacity/RGB sliders) --
    // Stored as separate 0-255 int channels rather than `color` properties
    // so persistence is plain JSON primitives, no color<->string round trip.
    property bool useCustomColors: false
    property int customSurfaceR: 28
    property int customSurfaceG: 28
    property int customSurfaceB: 38
    property real customOpacity: 1.0
    property int customAccentR: 91
    property int customAccentG: 140
    property int customAccentB: 255
    property bool customForegroundLight: true

    readonly property color customSurfaceOpaque: Qt.rgba(customSurfaceR / 255, customSurfaceG / 255, customSurfaceB / 255, 1)
    readonly property color customAccentColor: Qt.rgba(customAccentR / 255, customAccentG / 255, customAccentB / 255, 1)
    function presetSurface(key) {
        if (key === "adaptive") return adaptiveSurface;
        return key === "monoInvert" ? "#000000" : "#ffffff";
    }
    function presetForeground(key) {
        if (key === "adaptive") return adaptiveForeground;
        return key === "monoInvert" ? "#ffffff" : "#111111";
    }
    function presetMutedText(key) {
        return key === "adaptive" ? adaptiveMutedText : "#8a8a8a";
    }
    function presetAccent(key) {
        if (key === "adaptive") return adaptiveAccent;
        return key === "monoInvert" ? "#ffffff" : "#111111";
    }
    function presetUrgent(key) {
        if (key === "adaptive") return adaptiveUrgent;
        return key === "monoInvert" ? "#ff6b52" : "#d1341f";
    }

    readonly property color surface: useCustomColors
        ? Qt.rgba(customSurfaceR / 255, customSurfaceG / 255, customSurfaceB / 255, customOpacity)
        : presetSurface(presetKey)
    readonly property color foreground: useCustomColors
        ? (customForegroundLight ? "#f2f2f6" : "#101014")
        : presetForeground(presetKey)
    readonly property color mutedText: useCustomColors
        ? (customForegroundLight ? "#9a9aa8" : "#6a6a72")
        : presetMutedText(presetKey)
    readonly property color accent: useCustomColors ? customAccentColor : presetAccent(presetKey)
    readonly property color urgent: useCustomColors
        ? (relLuminance(customSurfaceOpaque) > 0.5 ? "#c81e28" : "#ff5c66")
        : presetUrgent(presetKey)
    // Color of the PanelWindow itself where no bar/menu shape is drawn.
    // Kept transparent so the desktop behind the bar stays visible.
    readonly property color barBg: "transparent"

    readonly property int barHeight: 40
    readonly property int menuTopRadius: 20
    readonly property int menuBottomRadius: 24

    function setPreset(key) {
        if (!presets[key]) return;
        presetKey = key;
        useCustomColors = false;
        persistence.adapter.presetKey = key;
        persistence.adapter.useCustomColors = false;
    }

    // Switches to the custom color preset. Never touches the custom
    // channels themselves, so Custom always keeps whatever colors were
    // last set on it, no matter which preset was active beforehand.
    function selectCustom() {
        if (useCustomColors) return;
        useCustomColors = true;
        persistence.adapter.useCustomColors = true;
    }

    // Explicit "take these colors" action: copies a preset's surface/accent
    // into the custom channels and switches to Custom. This is the only
    // path that overwrites custom colors with another theme's colors, and
    // it only runs when a button calls it directly.
    function applyPresetToCustom(key) {
        if (!presets[key]) return;
        const s = Qt.color(presetSurface(key));
        customSurfaceR = Math.round(s.r * 255);
        customSurfaceG = Math.round(s.g * 255);
        customSurfaceB = Math.round(s.b * 255);
        customOpacity = s.a;
        const a = Qt.color(presetAccent(key));
        customAccentR = Math.round(a.r * 255);
        customAccentG = Math.round(a.g * 255);
        customAccentB = Math.round(a.b * 255);
        customForegroundLight = relLuminance(s) < 0.5;
        useCustomColors = true;
        persistence.adapter.useCustomColors = true;
        persistence.adapter.customSurfaceR = customSurfaceR;
        persistence.adapter.customSurfaceG = customSurfaceG;
        persistence.adapter.customSurfaceB = customSurfaceB;
        persistence.adapter.customOpacity = customOpacity;
        persistence.adapter.customAccentR = customAccentR;
        persistence.adapter.customAccentG = customAccentG;
        persistence.adapter.customAccentB = customAccentB;
        persistence.adapter.customForegroundLight = customForegroundLight;
    }

    function setCustomSurfaceR(v) { selectCustom(); customSurfaceR = v; persistence.adapter.customSurfaceR = v; }
    function setCustomSurfaceG(v) { selectCustom(); customSurfaceG = v; persistence.adapter.customSurfaceG = v; }
    function setCustomSurfaceB(v) { selectCustom(); customSurfaceB = v; persistence.adapter.customSurfaceB = v; }
    function setCustomOpacity(v) { selectCustom(); customOpacity = v; persistence.adapter.customOpacity = v; }
    function setCustomAccentR(v) { selectCustom(); customAccentR = v; persistence.adapter.customAccentR = v; }
    function setCustomAccentG(v) { selectCustom(); customAccentG = v; persistence.adapter.customAccentG = v; }
    function setCustomAccentB(v) { selectCustom(); customAccentB = v; persistence.adapter.customAccentB = v; }
    function setCustomForegroundLight(v) { selectCustom(); customForegroundLight = v; persistence.adapter.customForegroundLight = v; }

    // Written to disk (not just kept across a `qs` reload) so the chosen
    // theme survives a full quickshell restart / login.
    property var persistence: FileView {
        id: persistence
        path: Quickshell.statePath("theme.json")
        watchChanges: true
        onLoaded: {
            theme.presetKey = adapter.presetKey;
            theme.useCustomColors = adapter.useCustomColors;
            theme.customSurfaceR = adapter.customSurfaceR;
            theme.customSurfaceG = adapter.customSurfaceG;
            theme.customSurfaceB = adapter.customSurfaceB;
            theme.customOpacity = adapter.customOpacity;
            theme.customAccentR = adapter.customAccentR;
            theme.customAccentG = adapter.customAccentG;
            theme.customAccentB = adapter.customAccentB;
            theme.customForegroundLight = adapter.customForegroundLight;
        }
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            property string presetKey: "mono"
            property bool useCustomColors: false
            property int customSurfaceR: 28
            property int customSurfaceG: 28
            property int customSurfaceB: 38
            property real customOpacity: 1.0
            property int customAccentR: 91
            property int customAccentG: 140
            property int customAccentB: 255
            property bool customForegroundLight: true
        }
    }
}
