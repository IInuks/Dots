pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool loaded: false

    property string themeMode: "dark" // "dark" | "light" | "adaptive"
    property int lastTab: 0
    property string wallpaperPath: ""

    property string weatherMode: "auto" // "auto" | "manual"
    property real weatherLat: 0
    property real weatherLon: 0
    property string weatherLabel: ""

    function setThemeMode(m) { root.themeMode = m; save(); }
    function setLastTab(t) { root.lastTab = t; save(); }
    function setWallpaperPath(p) { root.wallpaperPath = p; save(); }
    function setWeatherAuto() { root.weatherMode = "auto"; save(); }
    function setWeatherManual(lat, lon, label) {
        root.weatherMode = "manual";
        root.weatherLat = lat;
        root.weatherLon = lon;
        root.weatherLabel = label;
        save();
    }
    function cacheAutoLocation(lat, lon, label) {
        // Only used while weatherMode stays "auto" -- caches the IP lookup
        // so we don't re-hit the geolocation API on every restart.
        root.weatherLat = lat;
        root.weatherLon = lon;
        root.weatherLabel = label;
        save();
    }

    function save() {
        if (!root.loaded) return;
        file.adapter.themeMode = root.themeMode;
        file.adapter.lastTab = root.lastTab;
        file.adapter.wallpaperPath = root.wallpaperPath;
        file.adapter.weatherMode = root.weatherMode;
        file.adapter.weatherLat = root.weatherLat;
        file.adapter.weatherLon = root.weatherLon;
        file.adapter.weatherLabel = root.weatherLabel;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickbar/settings.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string themeMode: "dark"
            property int lastTab: 0
            property string wallpaperPath: ""
            property string weatherMode: "auto"
            property real weatherLat: 0
            property real weatherLon: 0
            property string weatherLabel: ""
        }

        onLoaded: {
            root.themeMode = adapter.themeMode;
            root.lastTab = adapter.lastTab;
            root.wallpaperPath = adapter.wallpaperPath;
            root.weatherMode = adapter.weatherMode;
            root.weatherLat = adapter.weatherLat;
            root.weatherLon = adapter.weatherLon;
            root.weatherLabel = adapter.weatherLabel;
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
