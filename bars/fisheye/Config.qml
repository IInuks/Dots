pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live-reloaded external config (~/.config/fisheye-bar/config.json), separate
// from Theme's palette file. Everything a user might want to flip without
// restarting the shell lives here. Root-level singleton (not nested under a
// config/ subdir) so every consumer anywhere in this tree can reach it via a
// pure ".." ancestor-chain import -- see the fisheye README note on why.
QtObject {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/fisheye-bar/config.json"

    property bool reducedMotion: false
    property string density: "normal" // "compact" | "normal"
    property bool bootSequence: true
    property bool debugOverlay: false
    property string clockFormat: "24h"
    property bool showSeconds: true
    property var moduleOrder: ["workspaces", "windowTitle", "clock", "media", "tray", "network", "bluetooth", "volume", "battery", "power"]
    property var visibleModules: ({})

    // IP-geolocation cache for ClockMenu's weather block, so a restart
    // doesn't re-hit the geolocation API before the first real weather
    // fetch. Same fields/shape as bars/floating's and bars/quickbar's
    // Settings.qml, minus the manual-override mode neither fisheye nor
    // this ask needs.
    property real weatherLat: 0
    property real weatherLon: 0
    property string weatherLabel: ""

    property FileView _file: FileView {
        path: root.configPath
        printErrors: false
        watchChanges: true
        onLoaded: root._apply(text())
        onLoadFailed: error => root._writeDefaults()
        onFileChanged: reload()
    }

    function _apply(text) {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            return;
        }
        if (d.reducedMotion !== undefined)
            root.reducedMotion = !!d.reducedMotion;
        if (d.density !== undefined)
            root.density = d.density;
        if (d.bootSequence !== undefined)
            root.bootSequence = !!d.bootSequence;
        if (d.debugOverlay !== undefined)
            root.debugOverlay = !!d.debugOverlay;
        if (d.clockFormat !== undefined)
            root.clockFormat = d.clockFormat;
        if (d.showSeconds !== undefined)
            root.showSeconds = !!d.showSeconds;
        if (d.moduleOrder !== undefined)
            root.moduleOrder = d.moduleOrder;
        if (d.visibleModules !== undefined)
            root.visibleModules = d.visibleModules;
        if (d.weatherLat !== undefined)
            root.weatherLat = d.weatherLat;
        if (d.weatherLon !== undefined)
            root.weatherLon = d.weatherLon;
        if (d.weatherLabel !== undefined)
            root.weatherLabel = d.weatherLabel;
    }

    function isVisible(name) {
        const v = root.visibleModules[name];
        return v === undefined ? true : !!v;
    }

    // Called once ClockMenu's IP lookup resolves, so the coordinates
    // survive a restart instead of re-querying ip-api.com every time.
    function cacheAutoLocation(lat, lon, label) {
        root.weatherLat = lat;
        root.weatherLon = lon;
        root.weatherLabel = label;
        root._save();
    }

    // Shared by first-run (_writeDefaults) and cacheAutoLocation: the
    // hardcoded defaults below are just the properties' own initial
    // values, so writing "current state" and "defaults" is the same call
    // on a fresh config.
    function _save() {
        root._file.setText(JSON.stringify({
            reducedMotion: root.reducedMotion,
            density: root.density,
            bootSequence: root.bootSequence,
            debugOverlay: root.debugOverlay,
            clockFormat: root.clockFormat,
            showSeconds: root.showSeconds,
            moduleOrder: root.moduleOrder,
            visibleModules: root.visibleModules,
            weatherLat: root.weatherLat,
            weatherLon: root.weatherLon,
            weatherLabel: root.weatherLabel
        }, null, 2));
    }

    function _writeDefaults() {
        root._save();
    }
}
