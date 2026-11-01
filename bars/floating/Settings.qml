pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Weather location persistence, ported from quickbar/Settings.qml (trimmed
// to just what this bar needs). Auto IP-geolocates on first run and caches
// the result -- per spec 4 "Kalender & Wetter", location should be
// configurable, but there's no need to interrupt the user on first launch
// when auto-detection already works.
QtObject {
    id: root

    property bool loaded: false

    property string themeMode: "mono" // "mono" | "adaptive"
    function setThemeMode(m) { root.themeMode = m; save(); }

    property string weatherMode: "auto" // "auto" | "manual"
    property real weatherLat: 0
    property real weatherLon: 0
    property string weatherLabel: ""

    function setWeatherAuto() { root.weatherMode = "auto"; save(); }
    function setWeatherManual(lat, lon, label) {
        root.weatherMode = "manual";
        root.weatherLat = lat;
        root.weatherLon = lon;
        root.weatherLabel = label;
        save();
    }
    function cacheAutoLocation(lat, lon, label) {
        if (root.weatherMode !== "auto") return;
        root.weatherLat = lat;
        root.weatherLon = lon;
        root.weatherLabel = label;
        save();
    }

    function save() {
        if (!root.loaded) return;
        file.adapter.themeMode = root.themeMode;
        file.adapter.weatherMode = root.weatherMode;
        file.adapter.weatherLat = root.weatherLat;
        file.adapter.weatherLon = root.weatherLon;
        file.adapter.weatherLabel = root.weatherLabel;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/floating-bar/settings.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string themeMode: "mono"
            property string weatherMode: "auto"
            property real weatherLat: 0
            property real weatherLon: 0
            property string weatherLabel: ""
        }

        onLoaded: {
            root.themeMode = adapter.themeMode;
            root.weatherMode = adapter.weatherMode;
            root.weatherLat = adapter.weatherLat;
            root.weatherLon = adapter.weatherLon;
            root.weatherLabel = adapter.weatherLabel;
            root.loaded = true;
        }
        onLoadFailed: (error) => {
            root.loaded = true;
            root.save();
        }
    }
}
