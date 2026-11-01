pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// Adaptive Material-You palette, sourced from the current wallpaper via
// matugen -- same proven Process-invocation pattern as bars/klasic/Theme.qml
// and bars/lucid/Theme.qml (both already debugged against the real
// installed matugen 4.2.0 binary on this system, see their comment blocks
// for the schema/flags investigation). New here: BOTH the "dark" and
// "light" branches of matugen's output are kept (not just "dark"), so
// Config.themeMode == "auto" can switch between them without a second
// matugen invocation.
//
// GTK/Qt/terminal application of this same palette does NOT happen here --
// it happens as a side effect of the `matugen image <path>` call itself,
// via [templates.*] entries in ~/.config/matugen/config.toml (see
// matugen-templates/ in this folder + README "System-Theming"). This
// singleton only ever reads matugen's stdout JSON for the bar/panels' own
// QML colors; Wallpaper.qml is what actually triggers the matugen run.
//
// Naming: every M3 "on_x" role is exposed as "xInk", never "onX" --
// Behavior-on a property matching /^on[A-Z]/ segfaults Quickshell on load
// (confirmed repeatedly: bars/blobs, bars/fisheye, bars/lucid; memory
// feedback_qml_behavior_on_property_naming_crash).
QtObject {
    id: root

    readonly property var _fallbackDark: ({
        background: "#15171c", backgroundInk: "#e2e5ec",
        surface: "#1b1e24", surfaceVariant: "#2a2e37",
        text: "#e2e5ec", textMuted: "#9aa1b0",
        accent: "#8ab4f8", accentInk: "#0a2540",
        border: "#343a46", urgent: "#f2a2a2"
    })
    readonly property var _fallbackLight: ({
        background: "#f4f5f9", backgroundInk: "#1b1e24",
        surface: "#ffffff", surfaceVariant: "#e4e6ee",
        text: "#1b1e24", textMuted: "#5c6270",
        accent: "#3a6ea5", accentInk: "#ffffff",
        border: "#d3d6e0", urgent: "#a3352f"
    })

    property var _paletteDark: null
    property var _paletteLight: null
    property bool matugenAvailable: false
    property bool matugenChecked: false

    // Written by Wallpaper.qml whenever the wallpaper actually changes
    // (apply()), so this singleton never has to independently watch
    // ~/.cache/wal/colors.json the way klasic/lucid do -- Wallpaper.qml is
    // already the single owner of "what is the current wallpaper" here.
    property string wallpaperPath: ""

    function regenerateAdaptive(path) {
        if (path) root.wallpaperPath = path;
        if (!root.wallpaperPath) return;
        matugenCheckProc.running = false;
        matugenCheckProc.running = true;
    }

    property Process matugenCheckProc: Process {
        command: ["sh", "-c", "command -v matugen"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.matugenAvailable = text.trim().length > 0;
                root.matugenChecked = true;
                if (root.matugenAvailable && root.wallpaperPath) root._runMatugen();
            }
        }
    }

    property Process matugenProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root._onMatugenOutput(text)
        }
    }

    function _runMatugen() {
        // --source-color-index 0 (dominant extracted color), not
        // --prefer saturation -- klasic's Theme.qml already compared both
        // against real wallpapers here and found saturation-preference
        // picks small vivid patches over the actual dominant color.
        //
        // --mode IS passed here (unlike klasic, which always used --mode
        // dark): matugen's JSON output contains dark+light+default
        // regardless of --mode (this QML only ever reads .dark/.light, see
        // _onMatugenOutput below), but --mode also controls which branch
        // "default" mirrors in the [templates.*] files matugen writes to
        // disk as a side effect of this same call (GTK/Qt, see README
        // "System-Theming") -- passing root.isLight keeps those disk
        // templates in sync with whichever branch the bar itself is
        // currently showing, including a pure day/night flip with no
        // wallpaper change (see onIsLightChanged below).
        matugenProc.command = ["matugen", "image", root.wallpaperPath, "--source-color-index", "0", "--mode", root.isLight ? "light" : "dark", "--json", "hex", "--quiet"];
        matugenProc.running = false;
        matugenProc.running = true;
    }

    // Re-renders the on-disk GTK/Qt templates (not just this QML's own
    // colors, which already read both branches from one JSON payload) when
    // Config.themeMode === "auto" crosses the 07:00/19:00 boundary with no
    // wallpaper change involved.
    onIsLightChanged: if (root.wallpaperPath) root.regenerateAdaptive()

    function _onMatugenOutput(text) {
        let data;
        try { data = JSON.parse(text); } catch (e) { return; }
        const colors = data && data.colors;
        if (!colors) return;

        function build(branch) {
            function get(role) {
                const c = colors[role];
                return c && c[branch] && c[branch].color;
            }
            const p = {
                background: get("background"),
                backgroundInk: get("on_background"),
                surface: get("surface_container_high"),
                surfaceVariant: get("surface_variant"),
                text: get("on_surface"),
                textMuted: get("on_surface_variant"),
                accent: get("primary"),
                accentInk: get("on_primary"),
                border: get("outline_variant"),
                urgent: get("error")
            };
            if (!(p.background && p.surface && p.text && p.accent)) return null;
            if (!p.backgroundInk) p.backgroundInk = p.text;
            if (!p.surfaceVariant) p.surfaceVariant = p.surface;
            if (!p.textMuted) p.textMuted = p.text;
            if (!p.accentInk) p.accentInk = p.background;
            if (!p.border) p.border = p.surfaceVariant;
            if (!p.urgent) p.urgent = "#f2a2a2";
            return p;
        }

        const dark = build("dark");
        const light = build("light");
        if (dark) root._paletteDark = dark;
        if (light) root._paletteLight = light;
    }

    // -- light/dark selection --

    property bool _autoIsLight: false
    function _recomputeAuto() {
        const h = new Date().getHours();
        root._autoIsLight = h >= 7 && h < 19;
    }
    property Timer _autoTimer: Timer {
        interval: 60000
        running: Config.ready && Config.themeMode === "auto"
        repeat: true
        triggeredOnStart: true
        onTriggered: root._recomputeAuto()
    }
    Component.onCompleted: root._recomputeAuto()

    readonly property bool isLight: {
        if (!Config.ready) return false;
        if (Config.themeMode === "light") return true;
        if (Config.themeMode === "dark") return false;
        return root._autoIsLight;
    }

    readonly property var active: {
        const p = root.isLight ? root._paletteLight : root._paletteDark;
        return p || (root.isLight ? root._fallbackLight : root._fallbackDark);
    }

    // Suppresses the initial fallback-palette -> real-palette jump from
    // animating; only changes after startup (wallpaper switch, mode
    // toggle) get a crossfade.
    property bool _crossfade: false
    property Timer _crossfadeArm: Timer { interval: 400; running: true; onTriggered: root._crossfade = true }

    property color background: active.background
    property color backgroundInk: active.backgroundInk
    property color surface: active.surface
    property color surfaceVariant: active.surfaceVariant
    property color text: active.text
    property color textMuted: active.textMuted
    property color accent: active.accent
    property color accentInk: active.accentInk
    property color border: active.border
    property color urgent: active.urgent

    Behavior on background { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on surface { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on surfaceVariant { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on text { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on textMuted { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on accent { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on border { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }

    // Bar strip alpha lives here as the one place transparency is allowed
    // to apply -- never a parent `opacity` (bleeds into text/icons).
    readonly property color barBackgroundColor: Qt.rgba(background.r, background.g, background.b, Config.ready ? Config.backgroundAlpha : 0.92)

    property int barHeight: 46
    property int sheetRadius: 20
    property int tileRadius: 14
    property int animFast: 140
    property int animMed: 220

    // Resolved explicitly against Qt.fontFamilies() rather than trusting
    // Qt's silent substitution -- same reasoning/pattern as
    // bars/lucid/Theme.qml. JetBrainsMono Nerd Font was confirmed
    // installed-but-not-yet-fontconfig-cached once already on this system
    // (memory: user-system) and material-symbols ships via the nixpkgs
    // package of the same name pulled in below in README "Nix-Pakete".
    readonly property var _availableFamilies: Qt.fontFamilies()
    readonly property string iconFontFamily: "Material Symbols Rounded"
    readonly property bool iconFontAvailable: root._availableFamilies.indexOf(root.iconFontFamily) !== -1
    readonly property string uiFontFamily: root._availableFamilies.indexOf("JetBrainsMono Nerd Font") !== -1 ? "JetBrainsMono Nerd Font" : "sans-serif"
}
