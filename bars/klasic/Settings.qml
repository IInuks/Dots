pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted state for the klasic bar. Lives under ~/.local/state (never in
// the shell directory itself) so it survives independent of how/where the
// klasic QML files are deployed.
QtObject {
    id: root

    property bool loaded: false

    property string themeId: "catppuccin-mocha" // one of themes/*.json basenames, or "adaptive"
    property real backgroundAlpha: 0.85 // 0..1, background-only transparency
    property string wallpaperPathOverride: "" // empty = auto-detect via ~/.cache/wal/colors.json

    function setThemeId(id) { root.themeId = id; save(); }
    function setBackgroundAlpha(a) { root.backgroundAlpha = Math.max(0, Math.min(1, a)); save(); }
    function setWallpaperPathOverride(p) { root.wallpaperPathOverride = p; save(); }

    function save() {
        if (!root.loaded) return;
        file.adapter.themeId = root.themeId;
        file.adapter.backgroundAlpha = root.backgroundAlpha;
        file.adapter.wallpaperPathOverride = root.wallpaperPathOverride;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/klasic/settings.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string themeId: "catppuccin-mocha"
            property real backgroundAlpha: 0.85
            property string wallpaperPathOverride: ""
        }

        onLoaded: {
            root.themeId = adapter.themeId;
            root.backgroundAlpha = adapter.backgroundAlpha;
            root.wallpaperPathOverride = adapter.wallpaperPathOverride;
            root.loaded = true;
        }
        onLoadFailed: (error) => {
            // No settings file yet on first-ever run -- defaults are fine,
            // and save() will create the file.
            root.loaded = true;
            root.save();
        }
    }
}
