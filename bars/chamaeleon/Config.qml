pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user choices. Theme.qml, the bar and the control center all
// just read from here -- this is the only place a setting is written.
QtObject {
    id: root

    property bool ready: false

    property string mode: "adaptive" // "dark" | "light" | "auto" | "adaptive"
    property string accentOverride: "" // "" = none, else "#rrggbb"
    property real barAlpha: 0.85
    property bool showTags: true
    property int autoLightStart: 7 // hour, 0-23
    property int autoLightEnd: 19

    function setMode(m) { root.mode = m; _persist(); }
    function setAccentOverride(hex) { root.accentOverride = hex; _persist(); }
    function setBarAlpha(v) { root.barAlpha = v; _persist(); }
    function setShowTags(v) { root.showTags = v; _persist(); }
    function setAutoWindow(startH, endH) { root.autoLightStart = startH; root.autoLightEnd = endH; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.mode = root.mode;
        _file.adapter.accentOverride = root.accentOverride;
        _file.adapter.barAlpha = root.barAlpha;
        _file.adapter.showTags = root.showTags;
        _file.adapter.autoLightStart = root.autoLightStart;
        _file.adapter.autoLightEnd = root.autoLightEnd;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.statePath("config.json")
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string mode: "adaptive"
            property string accentOverride: ""
            property real barAlpha: 0.85
            property bool showTags: true
            property int autoLightStart: 7
            property int autoLightEnd: 19
        }

        onLoaded: {
            root.mode = adapter.mode;
            root.accentOverride = adapter.accentOverride;
            root.barAlpha = adapter.barAlpha;
            root.showTags = adapter.showTags;
            root.autoLightStart = adapter.autoLightStart;
            root.autoLightEnd = adapter.autoLightEnd;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
