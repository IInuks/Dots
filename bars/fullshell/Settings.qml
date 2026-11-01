pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool loaded: false

    property string themeMode: "adaptive" // "dark" | "light" | "adaptive"
    property string wallpaperPath: ""
    property real barOpacity: 0.78 // 0.35..1.0, drives Theme.barAlpha
    property int lastTab: 0 // last open Command Center tab

    function setThemeMode(m) { root.themeMode = m; save(); }
    function setWallpaperPath(p) { root.wallpaperPath = p; save(); }
    function setBarOpacity(v) { root.barOpacity = v; save(); }
    function setLastTab(t) { root.lastTab = t; save(); }

    function save() {
        if (!root.loaded) return;
        file.adapter.themeMode = root.themeMode;
        file.adapter.wallpaperPath = root.wallpaperPath;
        file.adapter.barOpacity = root.barOpacity;
        file.adapter.lastTab = root.lastTab;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/fullshell/settings.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string themeMode: "adaptive"
            property string wallpaperPath: ""
            property real barOpacity: 0.78
            property int lastTab: 0
        }

        onLoaded: {
            root.themeMode = adapter.themeMode;
            root.wallpaperPath = adapter.wallpaperPath;
            root.barOpacity = adapter.barOpacity;
            root.lastTab = adapter.lastTab;
            root.loaded = true;
        }
        onLoadFailed: (error) => {
            root.loaded = true;
            root.save();
        }
    }
}
