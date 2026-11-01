pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user choices. Only place a setting gets written; everything
// else (Theme, Bar, ControlCenter) just reads from here.
QtObject {
    id: root

    property bool ready: false

    property string livery: "orange" // "orange" | "cyan" | "crimson" | "phosphor"
    property real barAlpha: 0.88
    property bool showTags: true
    property bool crtEffects: true
    property real crtIntensity: 0.5
    property bool crtFlicker: true

    function setLivery(v) { root.livery = v; _persist(); }
    function setBarAlpha(v) { root.barAlpha = v; _persist(); }
    function setShowTags(v) { root.showTags = v; _persist(); }
    function setCrtEffects(v) { root.crtEffects = v; _persist(); }
    function setCrtIntensity(v) { root.crtIntensity = v; _persist(); }
    function setCrtFlicker(v) { root.crtFlicker = v; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.livery = root.livery;
        _file.adapter.barAlpha = root.barAlpha;
        _file.adapter.showTags = root.showTags;
        _file.adapter.crtEffects = root.crtEffects;
        _file.adapter.crtIntensity = root.crtIntensity;
        _file.adapter.crtFlicker = root.crtFlicker;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.statePath("config.json")
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string livery: "orange"
            property real barAlpha: 0.88
            property bool showTags: true
            property bool crtEffects: true
            property real crtIntensity: 0.5
            property bool crtFlicker: true
        }

        onLoaded: {
            root.livery = adapter.livery;
            root.barAlpha = adapter.barAlpha;
            root.showTags = adapter.showTags;
            root.crtEffects = adapter.crtEffects;
            root.crtIntensity = adapter.crtIntensity;
            root.crtFlicker = adapter.crtFlicker;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
