import QtQuick
import Quickshell
import Quickshell.Io

// Loads a bar's theme. Colors (surface/foreground/accent) come live from
// adapters/live/<BarName>Live.qml when one exists for barName -- these
// read-only mirror each bar's own persisted state and color-resolution
// logic exactly (see those files), so the menu never drifts from what the
// bar actually looks like, without ever touching the bar's own files.
// barOpacity/radius/keybinds (structural, not "theme" colors) still come
// from adapters/<barName>.json, with adapters/_default.json as fallback --
// also the fallback for surface/foreground/accent on any bar without a
// live reader.
QtObject {
    id: root

    property string barName: ""
    readonly property string basePath: Quickshell.shellDir + "/adapters/"
    readonly property string liveBasePath: Quickshell.shellDir + "/adapters/live/"

    property FileView _specific: FileView {
        path: root.barName.length ? root.basePath + root.barName + ".json" : ""
        printErrors: false
        adapter: JsonAdapter {
            property string surface: ""
            property string foreground: ""
            property string accent: ""
            // -1 is the "not loaded" sentinel -- a real opacity is always 0..1.
            property real barOpacity: -1
            property int radius: -1
            property var keybinds: []
            property bool hasLauncher: false
        }
    }

    property FileView _default: FileView {
        path: root.basePath + "_default.json"
        printErrors: false
        adapter: JsonAdapter {
            property string surface: "#1c1c26"
            property string foreground: "#e8e8f0"
            property string accent: "#5b8cff"
            property real barOpacity: 0.9
            property int radius: 14
            property var keybinds: []
            property bool hasLauncher: false
        }
    }

    readonly property bool specificLoaded: _specific.adapter.barOpacity >= 0

    // Exactly one live reader loaded at a time, matching barName, so an
    // idle card never spins up another bar's file watchers/extraction
    // processes.
    property Loader _live: Loader {
        source: {
            if (root.barName === "quickbar") return root.liveBasePath + "QuickbarLive.qml";
            if (root.barName === "shellbar") return root.liveBasePath + "ShellbarLive.qml";
            if (root.barName === "klasic") return root.liveBasePath + "KlasicLive.qml";
            if (root.barName === "fullshell") return root.liveBasePath + "FullshellLive.qml";
            if (root.barName === "eierschale") return root.liveBasePath + "EierschaleLive.qml";
            if (root.barName === "drop") return root.liveBasePath + "DropLive.qml";
            if (root.barName.startsWith("custom-")) return root.liveBasePath + "CustomLive.qml";
            return "";
        }
        // CustomLive.qml serves every custom-* bar from one file, so unlike
        // the bar-specific readers above it needs to be told which slug.
        onLoaded: if (item && root.barName.startsWith("custom-")) item.slug = root.barName.substring("custom-".length)
    }
    readonly property bool _liveActive: _live.item !== null

    readonly property var surface: _liveActive ? _live.item.surface : (specificLoaded ? _specific.adapter.surface : _default.adapter.surface)
    readonly property var foreground: _liveActive ? _live.item.foreground : (specificLoaded ? _specific.adapter.foreground : _default.adapter.foreground)
    readonly property var accent: _liveActive ? _live.item.accent : (specificLoaded ? _specific.adapter.accent : _default.adapter.accent)
    readonly property real barOpacity: _liveActive ? _live.item.barOpacity : (specificLoaded ? _specific.adapter.barOpacity : _default.adapter.barOpacity)
    readonly property int radius: specificLoaded ? _specific.adapter.radius : _default.adapter.radius
    readonly property var keybinds: specificLoaded ? _specific.adapter.keybinds : _default.adapter.keybinds
    readonly property bool hasLauncher: specificLoaded ? _specific.adapter.hasLauncher : _default.adapter.hasLauncher
}
