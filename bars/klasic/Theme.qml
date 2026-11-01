pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// Central color singleton. Static themes are discovered from themes/*.json
// at runtime (drop a new file in there and it shows up -- no code change),
// plus one synthetic "adaptive" entry built from the current wallpaper via
// matugen (see _adaptive* below). Settings.themeId selects which one is
// active; nothing in the rest of the bar ever hardcodes a color.
QtObject {
    id: root

    readonly property string themesDir: Quickshell.shellDir + "/themes"

    // -- static themes, discovered from themes/*.json --

    property var _fileNames: []
    property var _loaded: ({}) // id -> {id, name, background, surface, text, textMuted, accent, border, urgent}
    property var themeList: [] // same objects, in discovery order

    property Process _listProc: Process {
        command: ["sh", "-c", "ls -1 " + root.themesDir + " 2>/dev/null | grep '\\.json$'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._fileNames = text.trim().split("\n")
                    .filter(l => l.length > 0)
                    .map(l => l.replace(/\.json$/, ""));
            }
        }
    }

    property var _themeFileLoader: Instantiator {
        model: root._fileNames
        delegate: FileView {
            required property string modelData
            path: root.themesDir + "/" + modelData + ".json"
            printErrors: false
            onLoaded: {
                let data;
                try { data = JSON.parse(text()); } catch (e) { return; }
                const merged = Object.assign({}, root._loaded);
                merged[modelData] = Object.assign({ id: modelData }, data);
                root._loaded = merged;
                root._rebuildThemeList();
            }
        }
    }

    function _rebuildThemeList() {
        root.themeList = root._fileNames.map(id => root._loaded[id]).filter(t => !!t);
    }

    readonly property var _fallback: ({
        id: "fallback",
        name: "Fallback",
        background: "#1e1e2e",
        surface: "#313244",
        text: "#cdd6f4",
        textMuted: "#a6adc8",
        accent: "#89b4fa",
        border: "#45475a",
        urgent: "#f38ba8"
    })

    // -- adaptive theme (matugen) --
    //
    // Schema verified against real `matugen 4.2.0` output (matugen's own
    // docs site is a JS SPA that doesn't render for automated fetching, so
    // this was checked by actually running the installed binary):
    //   { "colors": { "<role>": { "dark": {"color": "#hex"}, "default": {...}, "light": {...} } } }
    // Roles are the standard Material You names (primary, surface,
    // outline, error, ...). We always pass --mode dark, so "dark" and
    // "default" are identical here -- reading .dark.color directly.
    //
    // Non-interactive invocation needs --prefer: without it, an image with
    // several plausible dominant colors makes matugen prompt on stdin for a
    // choice and exit with an error when no terminal is attached (which is
    // always the case spawned from Quickshell) -- confirmed by actually
    // running `matugen image <file> --json hex` here without it first.

    property var adaptivePalette: null
    property bool matugenAvailable: false
    property bool matugenChecked: false

    property string wallpaperPath: Settings.wallpaperPathOverride.length > 0
        ? Settings.wallpaperPathOverride
        : root._autoWallpaperPath

    // Plain property, written from onAdapterUpdated below -- NOT a live
    // binding straight through `_walFile.adapter.wallpaper`, and NOT from
    // onLoaded either. Checked against FileView's real signal list
    // (quickshell-io.qmltypes): `loaded` only fires for the *initial* load;
    // an external change picked up via watchChanges re-parses the adapter
    // and fires `fileChanged`/`adapterUpdated`, not `loaded` again. Using
    // onLoaded (what bars/quickbar/Theme.qml does for this same file)
    // silently missed every wallpaper change after the first one -- caught
    // by actually running `wal -i <img> -n -q` (what shellwall calls) while
    // the bar was live and watching whether it reacted, not by assumption.
    property string _autoWallpaperPath: ""

    // Fallback wallpaper-path source: quickdots' wallpaper picker
    // (shellwall) already runs pywal per change (see shellwall/Config.qml,
    // runPywal:true) and bars/shellbar/Theme.qml reads this same file for
    // the same reason -- established convention in this project already.
    property FileView _walFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        printErrors: false
        adapter: JsonAdapter {
            property string wallpaper: ""
        }
        // `loaded` fires on every successful (re)parse, initial AND
        // explicit-reload-triggered alike -- but `watchChanges: true` by
        // itself only delivers the raw `fileChanged` notification that the
        // file differs; it does NOT re-parse the adapter on its own.
        // `adapterUpdated` (which looks like the "right" signal for this)
        // never actually fires for this FileView+JsonAdapter combination in
        // Quickshell 0.3.0 -- checked by adding console.warn to every
        // candidate signal and watching which ones actually printed while
        // running `wal -i <img> -n -q` (what shellwall calls) against a
        // live bar, not by trusting the qmltypes signal list alone.
        onLoaded: {
            if (adapter.wallpaper) root._autoWallpaperPath = adapter.wallpaper;
        }
        onFileChanged: reload()
    }
    // Re-checked every time regenerateAdaptive() runs (startup, wallpaper
    // change, or the popup's "Neu generieren" button) rather than once --
    // otherwise installing matugen after the bar's already running would
    // need a full bar restart before "Neu generieren" did anything.
    property Process _matugenCheckProc: Process {
        id: matugenCheckProc
        command: ["sh", "-c", "command -v matugen"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.matugenAvailable = text.trim().length > 0;
                root.matugenChecked = true;
                if (root.matugenAvailable && root.wallpaperPath) root._runMatugen();
            }
        }
    }

    Component.onCompleted: matugenCheckProc.running = true
    onWallpaperPathChanged: root.regenerateAdaptive()

    property Process _matugenProc: Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: root._onMatugenOutput(text)
        }
    }

    // Public entry point (startup, wallpaper change, "Neu generieren"):
    // always re-checks availability first.
    function regenerateAdaptive() {
        if (!root.wallpaperPath) return;
        matugenCheckProc.running = false;
        matugenCheckProc.running = true;
    }

    function _runMatugen() {
        // --source-color-index 0 (most dominant extracted color) instead
        // of --prefer saturation: saturation-preference kept picking small
        // but vivid warm/orange patches (skin tones, sunlit rock, wood)
        // over the image's actual dominant color -- e.g. a mostly-blue
        // mountain photo with a sunlit orange ridge came out orange.
        // Compared candidates via `matugen --show-source-colors` on
        // several real wallpapers here; index 0 tracked the visually
        // dominant color correctly on all of them, saturation didn't.
        matugenProc.command = ["matugen", "image", root.wallpaperPath, "--mode", "dark", "--source-color-index", "0", "--json", "hex", "--quiet"];
        matugenProc.running = false;
        matugenProc.running = true;
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
            name: "Adaptiv",
            background: get("background"),
            surface: get("surface_container_high"),
            text: get("on_background"),
            textMuted: get("on_surface_variant"),
            accent: get("primary"),
            border: get("outline_variant"),
            urgent: get("error")
        };

        // Need at least the core roles to be usable -- otherwise keep
        // whatever adaptivePalette we had (or null), Theme.active already
        // falls back safely.
        if (palette.background && palette.surface && palette.text && palette.accent) {
            if (!palette.textMuted) palette.textMuted = palette.text;
            if (!palette.border) palette.border = palette.surface;
            if (!palette.urgent) palette.urgent = "#f38ba8";
            root.adaptivePalette = palette;
        }
    }

    // -- active selection --

    readonly property var active: {
        if (Settings.themeId === "adaptive" && root.adaptivePalette) return root.adaptivePalette;
        return root._loaded[Settings.themeId] || root.themeList[0] || root._fallback;
    }

    property bool settingsReady: Settings.loaded
    onSettingsReadyChanged: if (settingsReady) enableCrossfade()

    property color background: active.background
    property color surface: active.surface
    property color text: active.text
    property color textMuted: active.textMuted
    property color accent: active.accent
    property color border: active.border
    property color urgent: active.urgent

    // The ONLY place transparency is allowed to apply: the bar strip's own
    // background rectangle uses this, never a parent `opacity` (which would
    // bleed into text/icons/tiles). Alpha channel only.
    readonly property color barBackgroundColor: Qt.rgba(background.r, background.g, background.b, Settings.backgroundAlpha)

    property bool _crossfade: false
    Behavior on background { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on surface { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on text { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on textMuted { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on accent { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on border { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    Behavior on urgent { enabled: root._crossfade; ColorAnimation { duration: root.animMed } }
    function enableCrossfade() { root._crossfade = true; }

    property int barHeight: 32
    property int radiusSmall: 6
    property int animFast: 140
    property int animMed: 260
}
