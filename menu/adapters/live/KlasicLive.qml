import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors bars/klasic/Theme.qml exactly: same themes/*.json lookup by
// themeId (with the same "first discovered theme" fallback while
// adaptive's matugen extraction hasn't produced a palette yet), same
// wallpaper -> matugen extraction for "adaptive". Reads klasic's own
// settings.json + themes/*.json read-only -- never writes, never imports
// klasic's QML.
QtObject {
    id: root

    readonly property string _klasicDir: Quickshell.shellDir + "/../../../bars/klasic"

    property FileView _settings: FileView {
        path: Quickshell.env("HOME") + "/.local/state/klasic/settings.json"
        printErrors: false
        watchChanges: true
        adapter: JsonAdapter {
            property string themeId: "catppuccin-mocha"
            property real backgroundAlpha: 0.85
            property string wallpaperPathOverride: ""
        }
        onFileChanged: reload()
    }

    // -- static themes, discovered from themes/*.json (same as klasic) --
    property var _fileNames: []
    property var _loaded: ({})
    property var themeList: []

    property Process _listProc: Process {
        command: ["sh", "-c", "ls -1 " + root._klasicDir + "/themes 2>/dev/null | grep '\\.json$'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._fileNames = text.trim().split("\n").filter(l => l.length > 0).map(l => l.replace(/\.json$/, ""));
            }
        }
    }

    property var _themeFileLoader: Instantiator {
        model: root._fileNames
        delegate: FileView {
            required property string modelData
            path: root._klasicDir + "/themes/" + modelData + ".json"
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

    readonly property var _fallback: ({ background: "#1e1e2e", surface: "#313244", text: "#cdd6f4", accent: "#89b4fa" })

    // -- adaptive (matugen) --
    property var adaptivePalette: null
    property string _lastWallpaperPath: ""

    property string _autoWallpaperPath: ""
    readonly property string wallpaperPath: _settings.adapter.wallpaperPathOverride.length > 0
        ? _settings.adapter.wallpaperPathOverride
        : root._autoWallpaperPath

    property FileView _walFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        printErrors: false
        adapter: JsonAdapter { property string wallpaper: "" }
        onLoaded: if (adapter.wallpaper) root._autoWallpaperPath = adapter.wallpaper
        onFileChanged: reload()
    }

    onWallpaperPathChanged: root._runMatugenIfNeeded()
    property string themeIdWatch: _settings.adapter.themeId
    onThemeIdWatchChanged: {
        root._lastWallpaperPath = "";
        root._runMatugenIfNeeded();
    }
    Component.onCompleted: root._runMatugenIfNeeded()

    function _runMatugenIfNeeded() {
        if (root.themeIdWatch !== "adaptive") return;
        if (!root.wallpaperPath || root.wallpaperPath === root._lastWallpaperPath) return;
        root._lastWallpaperPath = root.wallpaperPath;
        root._matugenProc.command = ["matugen", "image", root.wallpaperPath, "--mode", "dark", "--source-color-index", "0", "--json", "hex", "--quiet"];
        root._matugenProc.running = true;
    }

    property Process _matugenProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root._onMatugenOutput(text)
        }
    }

    function _onMatugenOutput(text) {
        let data;
        try { data = JSON.parse(text); } catch (e) { return; }
        const colors = data && data.colors;
        if (!colors) return;
        function get(role) { const c = colors[role]; return c && c.dark && c.dark.color; }
        const bg = get("background"), sf = get("surface_container_high"), tx = get("on_background"), ac = get("primary");
        if (bg && sf && tx && ac) root.adaptivePalette = { background: bg, surface: sf, text: tx, accent: ac };
    }

    readonly property var _active: {
        const id = _settings.adapter.themeId;
        if (id === "adaptive") {
            return root.adaptivePalette || (root.themeList.length ? root.themeList[0] : root._fallback);
        }
        return root._loaded[id] || (root.themeList.length ? root.themeList[0] : root._fallback);
    }

    readonly property string surface: _active.background
    readonly property string foreground: _active.text
    readonly property string accent: _active.accent
    readonly property real barOpacity: _settings.adapter.backgroundAlpha
}
