pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user choices for this shell. Everything else (Palette, the
// dock, the popups) just reads from here.
QtObject {
    id: root

    property bool ready: false

    property string mode: "adaptive" // "dark" | "light" | "adaptive"
    property real barAlpha: 0.86
    property bool dnd: false
    property string lastWallpaper: ""

    function setMode(m) { root.mode = m; _persist(); }
    function setBarAlpha(v) { root.barAlpha = v; _persist(); }
    function setDnd(v) { root.dnd = v; _persist(); }
    function setLastWallpaper(p) { root.lastWallpaper = p; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.mode = root.mode;
        _file.adapter.barAlpha = root.barAlpha;
        _file.adapter.dnd = root.dnd;
        _file.adapter.lastWallpaper = root.lastWallpaper;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/claude-shell/config.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string mode: "adaptive"
            property real barAlpha: 0.86
            property bool dnd: false
            property string lastWallpaper: ""
        }

        onLoaded: {
            root.mode = adapter.mode;
            root.barAlpha = adapter.barAlpha;
            root.dnd = adapter.dnd;
            root.lastWallpaper = adapter.lastWallpaper;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
