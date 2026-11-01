pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user choices, single write point (setX() functions), following
// the proven pattern from bars/chamaeleon/Config.qml. Everything else in
// this bar only reads from here.
//
// Deliberately ~/.config/lucidbar/config.json (not Quickshell.statePath(),
// which chamaeleon/claude use) -- this bar's own spec asked for that exact
// path explicitly.
QtObject {
    id: root

    property bool ready: false

    // "island": floating pills with a gap to the screen edge.
    // "notch": flush with the top edge, concave flares into the edge.
    property string shapeMode: "island"

    // "adaptive" (live matugen) | "catppuccin" | "gruvbox" | "nord" | "tokyonight"
    property string paletteId: "adaptive"

    property string uiFont: "Inter"

    property bool dnd: false

    // "" = not configured yet -- WeatherService shows a "Ort einstellen"
    // state instead of guessing a location.
    property string weatherLocation: ""

    // Per-module: enabled + which monitor it's pinned to ("" = every monitor).
    property var modules: ({
        tags: { enabled: true, monitor: "" },
        media: { enabled: true, monitor: "" },
        tray: { enabled: true, monitor: "" },
        clock: { enabled: true, monitor: "" },
        notifications: { enabled: true, monitor: "" },
        system: { enabled: true, monitor: "" }
    })

    function moduleEnabled(name) {
        const m = root.modules[name];
        return m ? m.enabled : true;
    }

    function moduleVisibleOn(name, screenName) {
        const m = root.modules[name];
        if (!m || !m.enabled)
            return false;
        return m.monitor === "" || m.monitor === screenName;
    }

    function setModuleEnabled(name, enabled) {
        const merged = Object.assign({}, root.modules);
        merged[name] = Object.assign({}, merged[name], { enabled: enabled });
        root.modules = merged;
        _persist();
    }

    function setModuleMonitor(name, monitor) {
        const merged = Object.assign({}, root.modules);
        merged[name] = Object.assign({}, merged[name], { monitor: monitor });
        root.modules = merged;
        _persist();
    }

    function setShapeMode(mode) { root.shapeMode = mode; _persist(); }
    function setPaletteId(id) { root.paletteId = id; _persist(); }
    function setUiFont(family) { root.uiFont = family; _persist(); }
    function setDnd(v) { root.dnd = v; _persist(); }
    function setWeatherLocation(v) { root.weatherLocation = v; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.shapeMode = root.shapeMode;
        _file.adapter.paletteId = root.paletteId;
        _file.adapter.uiFont = root.uiFont;
        _file.adapter.dnd = root.dnd;
        _file.adapter.weatherLocation = root.weatherLocation;
        _file.adapter.modules = root.modules;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.config/lucidbar/config.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string shapeMode: "island"
            property string paletteId: "adaptive"
            property string uiFont: "Inter"
            property bool dnd: false
            property string weatherLocation: ""
            property var modules: ({
                tags: { enabled: true, monitor: "" },
                media: { enabled: true, monitor: "" },
                tray: { enabled: true, monitor: "" },
                clock: { enabled: true, monitor: "" },
                notifications: { enabled: true, monitor: "" },
                system: { enabled: true, monitor: "" }
            })
        }

        onLoaded: {
            root.shapeMode = adapter.shapeMode;
            root.paletteId = adapter.paletteId;
            root.uiFont = adapter.uiFont;
            root.dnd = adapter.dnd;
            root.weatherLocation = adapter.weatherLocation;
            root.modules = adapter.modules;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
