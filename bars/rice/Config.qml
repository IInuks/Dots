pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user choices, single write point (setX() functions), following
// the proven pattern from bars/lucid/Config.qml (itself from
// bars/chamaeleon/Config.qml). Everything else in this bar only reads
// from here. -> ~/.config/ricebar/config.json
QtObject {
    id: root

    property bool ready: false

    // "auto" = light 07:00-19:00, dark otherwise (see Theme.qml's minute
    // Timer). "light"/"dark" = forced, no Timer re-evaluation needed.
    property string themeMode: "auto"

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
    property var wallpaperExtensions: ["jpg", "jpeg", "png", "webp"]

    // awww = nixpkgs' swww successor (CLI identical), same binary every
    // other quickdots wallpaper consumer (shellwall, lumen) already calls.
    property string wallpaperBinary: "awww"
    property string transitionType: "simple"
    property int transitionFps: 60

    property bool slideshowEnabled: false
    property int slideshowIntervalMin: 30

    property bool autoHideBar: false
    property real backgroundAlpha: 0.92

    property bool dnd: false

    function setThemeMode(v) { root.themeMode = v; _persist(); }
    function setWallpaperDir(v) { root.wallpaperDir = v; _persist(); }
    function setSlideshowEnabled(v) { root.slideshowEnabled = v; _persist(); }
    function setSlideshowIntervalMin(v) { root.slideshowIntervalMin = v; _persist(); }
    function setAutoHideBar(v) { root.autoHideBar = v; _persist(); }
    function setDnd(v) { root.dnd = v; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.themeMode = root.themeMode;
        _file.adapter.wallpaperDir = root.wallpaperDir;
        _file.adapter.wallpaperExtensions = root.wallpaperExtensions;
        _file.adapter.wallpaperBinary = root.wallpaperBinary;
        _file.adapter.transitionType = root.transitionType;
        _file.adapter.transitionFps = root.transitionFps;
        _file.adapter.slideshowEnabled = root.slideshowEnabled;
        _file.adapter.slideshowIntervalMin = root.slideshowIntervalMin;
        _file.adapter.autoHideBar = root.autoHideBar;
        _file.adapter.backgroundAlpha = root.backgroundAlpha;
        _file.adapter.dnd = root.dnd;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.config/ricebar/config.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string themeMode: "auto"
            property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
            property var wallpaperExtensions: ["jpg", "jpeg", "png", "webp"]
            property string wallpaperBinary: "awww"
            property string transitionType: "simple"
            property int transitionFps: 60
            property bool slideshowEnabled: false
            property int slideshowIntervalMin: 30
            property bool autoHideBar: false
            property real backgroundAlpha: 0.92
            property bool dnd: false
        }

        onLoaded: {
            root.themeMode = adapter.themeMode;
            root.wallpaperDir = adapter.wallpaperDir;
            root.wallpaperExtensions = adapter.wallpaperExtensions;
            root.wallpaperBinary = adapter.wallpaperBinary;
            root.transitionType = adapter.transitionType;
            root.transitionFps = adapter.transitionFps;
            root.slideshowEnabled = adapter.slideshowEnabled;
            root.slideshowIntervalMin = adapter.slideshowIntervalMin;
            root.autoHideBar = adapter.autoHideBar;
            root.backgroundAlpha = adapter.backgroundAlpha;
            root.dnd = adapter.dnd;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
