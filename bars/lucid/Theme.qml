pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for every color, radius, duration and easing.
// Root-level singleton (not nested under Bar/ or Panels/) so every file
// reaches it via a pure ".." ancestor-chain import -- a sideways/symlinked
// import of a pragma-Singleton silently returns all-undefined properties in
// this Quickshell version, no error at all (confirmed in bars/lumen,
// bars/fisheye, bars/claude before this one).
//
// -- Palette sourcing --------------------------------------------------
// Config.paletteId selects one of: "adaptive" (live matugen) or one of the
// four fixed presets (catppuccin/gruvbox/nord/tokyonight).
//
// "adaptive" invokes `matugen image <wallpaper>` itself, following the
// already-proven approach from bars/klasic/Theme.qml rather than the
// FileView-on-a-generated-file design originally sketched for this bar --
// deliberate deviation, see the block below the fixed palettes for why.
//
// -- Naming pitfalls (confirmed repeatedly across sibling bars) --------
// - A singleton named "Theme"/"Colors"/"Palette" is fine; "Palette" itself
//   collides with a QtQuick builtin (bars/claude bug log) -- avoided here.
// - Property names matching /^on[A-Z]/ (the literal Material "onSurface"
//   spelling) are read as signal-handler slots by this engine's Behavior
//   wiring and reproducibly segfault Quickshell on load (bars/blobs,
//   bars/fisheye, memory: feedback_qml_behavior_on_property_naming_crash).
//   Every M3 "on_x" role is therefore exposed here as "xInk", never "onX".
QtObject {
    id: root

    // ===================================================================
    // Motion -- the only place a duration/spring constant is spelled out.
    // M3 Expressive leans on spring/bounce motion rather than pure easing
    // curves; SpringAnimation (mass/stiffness modeled as spring+damping)
    // is used for the pill<->panel morph, plain easing for color crossfade.
    // ===================================================================
    readonly property real morphSpring: 2.8
    readonly property real morphDamping: 0.42
    readonly property real hoverSpring: 3.4
    readonly property real hoverDamping: 0.5

    readonly property int durFast: 120
    readonly property int durBase: 220
    readonly property int durSlow: 380
    readonly property int durPalette: 320 // color crossfade on palette/wallpaper swap

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack // M3 "emphasized decelerate" approximation

    // ===================================================================
    // Shape
    // ===================================================================
    readonly property int radiusPill: 22 // fully-rounded collapsed pill
    readonly property int radiusPanel: 28 // expanded panel corner radius
    readonly property int pillHeight: 40
    readonly property int pillGap: 10
    readonly property int islandMargin: 10 // gap to screen edge in "island" mode
    // "notch" sits flush with the screen edge, "island" floats with a gap --
    // read by Bar.qml for both the window's top margin and its exclusiveZone.
    readonly property int barTopMargin: Config.shapeMode === "notch" ? 0 : root.islandMargin
    // Tallest any single module's open panel is allowed to get -- sets the
    // shared bar window's implicitHeight (see bars/blobs/Bar.qml for the
    // same "oversized window + mask" technique). Generous placeholder,
    // revisited once every module's real panel size is known.
    readonly property int maxPanelHeight: 460

    // ===================================================================
    // Fixed palettes -- M3-role-shaped objects, same keys the matugen
    // path below produces, so every consumer reads root.<role> uniformly
    // regardless of source.
    // ===================================================================
    readonly property var _catppuccinMocha: ({
        background: "#1e1e2e", backgroundInk: "#cdd6f4",
        surface: "#181825", surfaceInk: "#cdd6f4",
        surfaceVariant: "#313244", surfaceVariantInk: "#bac2de",
        surfaceContainer: "#313244",
        primary: "#cba6f7", primaryInk: "#1e1e2e",
        primaryContainer: "#45475a", primaryContainerInk: "#cba6f7",
        secondary: "#89b4fa", secondaryInk: "#1e1e2e",
        tertiary: "#94e2d5", tertiaryInk: "#1e1e2e",
        critical: "#f38ba8", criticalInk: "#1e1e2e",
        outline: "#6c7086", outlineVariant: "#45475a",
        shadow: "#11111b", scrim: "#11111b"
    })
    readonly property var _gruvbox: ({
        background: "#282828", backgroundInk: "#ebdbb2",
        surface: "#1d2021", surfaceInk: "#ebdbb2",
        surfaceVariant: "#3c3836", surfaceVariantInk: "#d5c4a1",
        surfaceContainer: "#3c3836",
        primary: "#fabd2f", primaryInk: "#282828",
        primaryContainer: "#504945", primaryContainerInk: "#fabd2f",
        secondary: "#83a598", secondaryInk: "#282828",
        tertiary: "#b8bb26", tertiaryInk: "#282828",
        critical: "#fb4934", criticalInk: "#282828",
        outline: "#7c6f64", outlineVariant: "#504945",
        shadow: "#1d2021", scrim: "#1d2021"
    })
    readonly property var _nord: ({
        background: "#2e3440", backgroundInk: "#eceff4",
        surface: "#242933", surfaceInk: "#eceff4",
        surfaceVariant: "#3b4252", surfaceVariantInk: "#d8dee9",
        surfaceContainer: "#3b4252",
        primary: "#88c0d0", primaryInk: "#2e3440",
        primaryContainer: "#434c5e", primaryContainerInk: "#88c0d0",
        secondary: "#81a1c1", secondaryInk: "#2e3440",
        tertiary: "#a3be8c", tertiaryInk: "#2e3440",
        critical: "#bf616a", criticalInk: "#2e3440",
        outline: "#4c566a", outlineVariant: "#434c5e",
        shadow: "#242933", scrim: "#242933"
    })
    readonly property var _tokyoNight: ({
        background: "#1a1b26", backgroundInk: "#c0caf5",
        surface: "#16161e", surfaceInk: "#c0caf5",
        surfaceVariant: "#292e42", surfaceVariantInk: "#a9b1d6",
        surfaceContainer: "#24283b",
        primary: "#7aa2f7", primaryInk: "#1a1b26",
        primaryContainer: "#292e42", primaryContainerInk: "#7aa2f7",
        secondary: "#bb9af7", secondaryInk: "#1a1b26",
        tertiary: "#9ece6a", tertiaryInk: "#1a1b26",
        critical: "#f7768e", criticalInk: "#1a1b26",
        outline: "#565f89", outlineVariant: "#292e42",
        shadow: "#16161e", scrim: "#16161e"
    })
    readonly property var _fallback: ({
        background: "#141318", backgroundInk: "#e6e1e9",
        surface: "#0f0e13", surfaceInk: "#e6e1e9",
        surfaceVariant: "#2a2830", surfaceVariantInk: "#cbc4cf",
        surfaceContainer: "#211f26",
        primary: "#8ab4f8", primaryInk: "#0a1a33",
        primaryContainer: "#33445c", primaryContainerInk: "#8ab4f8",
        secondary: "#c9bfe0", secondaryInk: "#1a1626",
        tertiary: "#7fd8c0", tertiaryInk: "#0a2620",
        critical: "#ff6b6b", criticalInk: "#2a0e0e",
        outline: "#928f99", outlineVariant: "#49454f",
        shadow: "#000000", scrim: "#000000"
    })

    readonly property var _presets: ({
        catppuccin: root._catppuccinMocha,
        gruvbox: root._gruvbox,
        nord: root._nord,
        tokyonight: root._tokyoNight
    })

    // ===================================================================
    // Adaptive palette -- matugen invoked directly as a Process, exactly
    // like bars/klasic/Theme.qml, deliberately NOT the FileView-reads-
    // ~/.cache/quickshell/matugen.json design this bar was originally
    // spec'd with. Two things learned from klasic's (already-debugged)
    // comments made that call:
    //  1. Real `matugen --json hex` output (verified there against the
    //     actually-installed 4.2.0 binary, matugen's own doc site is a JS
    //     SPA that doesn't render for fetching) is
    //       { "colors": { "<role>": { "dark": {"color": "#hex"}, ... } } }
    //     -- nested per-role dark/default/light, NOT the flat role->hex
    //     map this bar's spec assumed. A literal ~/.cache/quickshell/
    //     matugen.json flat file would have to be hand-built from that
    //     nested shape anyway, so writing+re-reading a file buys nothing
    //     a plain in-memory property doesn't already give.
    //  2. Needs --source-color-index or --prefer, or matugen prompts on
    //     stdin (no terminal attached when spawned from Quickshell) and
    //     the process just hangs/errors. --source-color-index 0 already
    //     empirically beat --prefer saturation on this system's real
    //     wallpapers (klasic's comment: saturation-preference kept picking
    //     small vivid patches over the actually-dominant color).
    // Wallpaper-change detection still goes through FileView, just on the
    // one file something external actually writes: pywal's
    // ~/.cache/wal/colors.json (written by `wal`, which shellwall already
    // runs on every wallpaper change, runPywal:true) -- same convention
    // bars/klasic and bars/fisheye already rely on.
    // ===================================================================
    property var _adaptiveRaw: null
    property bool matugenAvailable: false
    property bool matugenChecked: false
    property string wallpaperPath: ""

    property FileView _walFile: FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        printErrors: false
        adapter: JsonAdapter {
            property string wallpaper: ""
        }
        // `loaded` only fires for the initial parse; a later external
        // rewrite delivers `fileChanged`, not `loaded` again, and
        // `adapterUpdated` never actually fires for this FileView+
        // JsonAdapter combination in Quickshell 0.3.0 (bars/klasic
        // confirmed this by instrumenting every candidate signal against
        // a live `wal -i ... -n -q` run). Read the adapter value inside
        // onLoaded into a plain property instead of binding through it.
        onLoaded: {
            if (adapter.wallpaper)
                root.wallpaperPath = adapter.wallpaper;
        }
        onFileChanged: reload()
    }

    property Process _matugenCheckProc: Process {
        id: matugenCheckProc
        command: ["sh", "-c", "command -v matugen"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.matugenAvailable = text.trim().length > 0;
                root.matugenChecked = true;
                if (root.matugenAvailable && root.wallpaperPath)
                    root._runMatugen();
            }
        }
    }

    onWallpaperPathChanged: regenerateAdaptive()
    Component.onCompleted: matugenCheckProc.running = true

    // Public entry point (startup, wallpaper change, future "regenerate"
    // action) -- re-checks availability every time rather than once, so
    // installing matugen after the bar is already running doesn't need a
    // restart before it starts working.
    function regenerateAdaptive() {
        if (!root.wallpaperPath)
            return;
        matugenCheckProc.running = false;
        matugenCheckProc.running = true;
    }

    property Process _matugenProc: Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: root._onMatugenOutput(text)
        }
    }

    function _runMatugen() {
        matugenProc.command = ["matugen", "image", root.wallpaperPath, "--mode", "dark", "--source-color-index", "0", "--json", "hex", "--quiet"];
        matugenProc.running = false;
        matugenProc.running = true;
    }

    function _onMatugenOutput(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        const c = data && data.colors;
        if (!c)
            return;
        function get(role) {
            const r = c[role];
            return r && r.dark && r.dark.color;
        }
        const palette = {
            background: get("background"), backgroundInk: get("on_background"),
            surface: get("surface"), surfaceInk: get("on_surface"),
            surfaceVariant: get("surface_variant"), surfaceVariantInk: get("on_surface_variant"),
            surfaceContainer: get("surface_container_high") || get("surface_container"),
            primary: get("primary"), primaryInk: get("on_primary"),
            primaryContainer: get("primary_container"), primaryContainerInk: get("on_primary_container"),
            secondary: get("secondary"), secondaryInk: get("on_secondary"),
            tertiary: get("tertiary"), tertiaryInk: get("on_tertiary"),
            critical: get("error"), criticalInk: get("on_error"),
            outline: get("outline"), outlineVariant: get("outline_variant"),
            shadow: get("shadow"), scrim: get("scrim")
        };
        if (palette.background && palette.surface && palette.primary)
            root._adaptiveRaw = palette;
    }

    // ===================================================================
    // Active selection
    // ===================================================================
    readonly property var active: {
        if (Config.paletteId === "adaptive" && root._adaptiveRaw)
            return root._adaptiveRaw;
        return root._presets[Config.paletteId] || root._fallback;
    }

    property color background: active.background
    property color backgroundInk: active.backgroundInk
    property color surface: active.surface
    property color surfaceInk: active.surfaceInk
    property color surfaceVariant: active.surfaceVariant
    property color surfaceVariantInk: active.surfaceVariantInk
    property color surfaceContainer: active.surfaceContainer
    property color primary: active.primary
    property color primaryInk: active.primaryInk
    property color primaryContainer: active.primaryContainer
    property color primaryContainerInk: active.primaryContainerInk
    property color secondary: active.secondary
    property color secondaryInk: active.secondaryInk
    property color tertiary: active.tertiary
    property color tertiaryInk: active.tertiaryInk
    property color critical: active.critical
    property color criticalInk: active.criticalInk
    property color outline: active.outline
    property color outlineVariant: active.outlineVariant
    property color shadow: active.shadow
    property color scrim: active.scrim

    Behavior on background { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on surface { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on surfaceVariant { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainer { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on primary { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on primaryContainer { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on secondary { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on tertiary { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on critical { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }
    Behavior on outline { ColorAnimation { duration: root.durPalette; easing.type: Easing.InOutQuad } }

    // ===================================================================
    // Fonts -- Material Symbols Rounded (pkgs.material-symbols) for icons,
    // configurable UI font with a fallback family if the desired one isn't
    // installed. Qt silently substitutes an unavailable family with a
    // generic default rather than erroring, but that default is usually
    // ugly/inconsistent -- resolve explicitly against Qt.fontFamilies()
    // so Config.uiFont's *intended* fallback chain is what actually shows.
    readonly property string iconFontFamily: "Material Symbols Rounded"
    readonly property var _availableFamilies: Qt.fontFamilies()
    readonly property bool iconFontAvailable: root._availableFamilies.indexOf(root.iconFontFamily) !== -1
    readonly property string uiFontFamily: root._availableFamilies.indexOf(Config.uiFont) !== -1 ? Config.uiFont : "sans-serif"
}
