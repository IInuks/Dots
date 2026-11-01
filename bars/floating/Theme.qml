pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Two palettes: the spec's static Mr.-Robot monochrome look ("mono", the
// default), and an "adaptive" one derived from the current wallpaper via
// matugen -- same technique as klasic/Theme.qml, trimmed to the handful of
// roles this bar actually uses (background/border/text/textMuted/urgent;
// no separate "surface"/"accent" here since islands only ever need one
// background+border+text set). Settings.themeMode picks which is active;
// switched from the round button on the left island (see
// left/ThemeSwitcherPopup.qml). Geometry/font/animation constants below are
// unaffected by theme and stay plain static values.
QtObject {
    id: root

    readonly property var _monoPalette: ({
        id: "mono",
        background: "#141619",
        border: "#8a8f98",
        text: "#c9ccd1",
        textMuted: "#8a8f98", // alpha applied below via textMuted binding
        urgent: "#e05a4e"
    })

    // -- adaptive palette (matugen) --
    //
    // Schema verified in klasic/Theme.qml against real `matugen 4.2.0`
    // output: { "colors": { "<role>": { "dark": {"color": "#hex"}, ... } } }.
    // Always pass --mode dark, so "dark" is what we read. --source-color-index
    // 0 (dominant color) rather than --prefer saturation -- klasic found
    // saturation-preference picks small vivid patches over the image's
    // actual dominant color on real wallpapers here.

    property var adaptivePalette: null
    property bool matugenAvailable: false

    property string wallpaperPath: ""
    property FileView _walFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        printErrors: false
        adapter: JsonAdapter {
            property string wallpaper: ""
        }
        onLoaded: {
            if (adapter.wallpaper) root.wallpaperPath = adapter.wallpaper;
        }
        onFileChanged: reload()
    }

    property Process _matugenCheckProc: Process {
        command: ["sh", "-c", "command -v matugen"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.matugenAvailable = text.trim().length > 0;
                if (root.matugenAvailable && root.wallpaperPath) root._runMatugen();
            }
        }
    }
    onWallpaperPathChanged: root.refreshAdaptive()
    // Public retry entry point: ThemeSwitcherPopup calls this on open if
    // adaptivePalette is still null, in case the initial check ran before
    // the wallpaper path or matugen availability was ready.
    function refreshAdaptive() {
        _matugenCheckProc.running = false;
        _matugenCheckProc.running = true;
    }

    property Process _matugenProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root._onMatugenOutput(text)
        }
    }
    function _runMatugen() {
        _matugenProc.command = ["matugen", "image", root.wallpaperPath, "--mode", "dark", "--source-color-index", "0", "--json", "hex", "--quiet"];
        _matugenProc.running = false;
        _matugenProc.running = true;
    }
    function _onMatugenOutput(text) {
        let data;
        try { data = JSON.parse(text); } catch (e) { return; }
        const colors = data && data.colors;
        if (!colors) return;
        function get(role) {
            const c = colors[role];
            return c && c.dark && c.dark.color;
        }
        const palette = {
            id: "adaptive",
            background: get("background"),
            border: get("outline_variant"),
            text: get("on_background"),
            textMuted: get("on_surface_variant"),
            urgent: get("error")
        };
        if (palette.background && palette.text) {
            if (!palette.border) palette.border = Qt.alpha(palette.text, 0.4);
            if (!palette.textMuted) palette.textMuted = Qt.alpha(palette.text, 0.6);
            if (!palette.urgent) palette.urgent = "#e05a4e";
            root.adaptivePalette = palette;
        }
    }

    // -- active selection --

    readonly property var active: {
        if (Settings.themeMode === "adaptive" && root.adaptivePalette) return root.adaptivePalette;
        return root._monoPalette;
    }

    property bool _crossfade: false
    Component.onCompleted: {
        _matugenCheckProc.running = true;
        Qt.callLater(() => root._crossfade = true);
    }

    property color background: active.background
    property color border: active.border
    property color text: active.text
    property color textMuted: Qt.alpha(active.text, active.id === "mono" ? 0.6 : 0.65)
    property color urgent: active.urgent
    Behavior on background { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on border { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on text { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on textMuted { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on urgent { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }

    readonly property real backgroundOpacity: 0.85
    readonly property color islandBackgroundColor: Qt.rgba(background.r, background.g, background.b, backgroundOpacity)
    readonly property real borderOpacity: 0.5
    readonly property color islandBorderColor: Qt.rgba(border.r, border.g, border.b, borderOpacity)

    readonly property color activeHighlight: Qt.alpha(text, 0.10)
    readonly property color activeBorder: Qt.alpha(text, 0.55)

    // -- island geometry (theme-independent) --
    readonly property int islandHeight: 28
    readonly property int islandRadius: 8
    readonly property int islandBorderWidth: 1
    readonly property int marginTop: 6
    readonly property int marginSide: 8
    readonly property int paddingHorizontal: 10
    readonly property int moduleSpacing: 12
    readonly property int popupGap: 6
    // Height of the invisible top-edge exclusiveZone reservation
    // (TopGapReserve.qml) that keeps tiled windows clear of the bar without
    // touching mango's gappov (symmetric top+bottom, see conversation).
    // mango offsets every same-edge layer-shell surface's position by the
    // cumulative exclusiveZone of other same-edge surfaces regardless of
    // layer, so the reservation surface's zone also pushes the islands/toast
    // down by this amount -- their own margins.top subtracts it back out
    // (see IslandBase.qml, Toast.qml) to land at the intended marginTop.
    readonly property int topReserveZone: marginTop + islandHeight

    // -- fonts --
    readonly property string fontFamily: "monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeBigClock: 40

    // -- animation --
    readonly property int animFast: 120
    readonly property int animMed: 200
}
