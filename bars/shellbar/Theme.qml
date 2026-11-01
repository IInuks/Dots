pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Central theme singleton. Holds color presets + shared geometry constants
// (bar height, liquid-menu radii) so every module and LiquidMenu instance
// stays in sync when the preset is switched live.
QtObject {
    id: theme

    // Live wallpaper palette for the "Adaptive" preset below. quickwall reruns
    // pywal on every wallpaper change and rewrites this file in place, so
    // watchChanges + reload() keeps `wal.parsed` current without a restart.
    property var wal: FileView {
        id: wal
        path: "~/.cache/wal/colors.json"
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

    function relLuminance(hex) {
        const c = Qt.color(hex);
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    readonly property color adaptiveSurface: wal.parsed ? wal.parsed.special.background : "#1c1c26"
    readonly property color adaptiveForeground: wal.parsed ? wal.parsed.special.foreground : "#e8e8f0"
    readonly property color adaptiveMutedText: wal.parsed ? wal.parsed.colors.color8 : "#8d8da0"
    readonly property color adaptiveAccent: wal.parsed ? wal.parsed.colors.color4 : "#5b8cff"
    // pywal's palette isn't guaranteed to contain an actual red, so urgent
    // stays a fixed alert red, just picked light/dark to fit the wallpaper's
    // background instead of the fixed hue every other preset uses.
    readonly property color adaptiveUrgent: wal.parsed && relLuminance(wal.parsed.special.background) > 0.5 ? "#c81e28" : "#ff5c66"

    readonly property var presets: ({
        adaptive: {
            label: "Adaptive",
            surface: adaptiveSurface,
            foreground: adaptiveForeground,
            mutedText: adaptiveMutedText,
            accent: adaptiveAccent,
            urgent: adaptiveUrgent
        },
        mono: {
            label: "Mono",
            surface: "#ffffff",
            foreground: "#111111",
            mutedText: "#8a8a8a",
            accent: "#111111",
            urgent: "#d1341f"
        },
        monoInvert: {
            label: "Mono Invert",
            surface: "#000000",
            foreground: "#ffffff",
            mutedText: "#8a8a8a",
            accent: "#ffffff",
            urgent: "#ff6b52"
        }
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
    readonly property var customPreset: ({
        label: "Custom",
        surface: Qt.rgba(customSurfaceR / 255, customSurfaceG / 255, customSurfaceB / 255, customOpacity),
        foreground: customForegroundLight ? "#f2f2f6" : "#101014",
        mutedText: customForegroundLight ? "#9a9aa8" : "#6a6a72",
        accent: customAccentColor,
        urgent: relLuminance(customSurfaceOpaque) > 0.5 ? "#c81e28" : "#ff5c66"
    })

    readonly property var current: useCustomColors ? customPreset : (presets[presetKey] ?? presets.mono)

    readonly property color surface: current.surface
    readonly property color foreground: current.foreground
    readonly property color mutedText: current.mutedText
    readonly property color accent: current.accent
    readonly property color urgent: current.urgent
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
        const preset = presets[key];
        if (!preset) return;
        const s = Qt.color(preset.surface);
        customSurfaceR = Math.round(s.r * 255);
        customSurfaceG = Math.round(s.g * 255);
        customSurfaceB = Math.round(s.b * 255);
        customOpacity = s.a;
        const a = Qt.color(preset.accent);
        customAccentR = Math.round(a.r * 255);
        customAccentG = Math.round(a.g * 255);
        customAccentB = Math.round(a.b * 255);
        customForegroundLight = relLuminance(preset.surface) < 0.5;
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
