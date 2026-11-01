pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user preferences for the weich bar. Currently just the
// transparency toggle exposed in SettingsPopup, kept as its own file since
// Theme.qml reads it (Theme must not own its own persistence).
QtObject {
    id: root

    property bool loaded: false
    property bool transparencyEnabled: true

    function setTransparency(enabled) {
        root.transparencyEnabled = enabled;
        save();
    }
    function toggleTransparency() {
        setTransparency(!root.transparencyEnabled);
    }

    function save() {
        if (!root.loaded) return; // avoid clobbering the file with defaults before the initial load completes
        file.adapter.transparencyEnabled = root.transparencyEnabled;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/weich-bar/settings.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property bool transparencyEnabled: true
        }

        onLoaded: {
            root.transparencyEnabled = adapter.transparencyEnabled;
            root.loaded = true;
        }
        onLoadFailed: (error) => {
            root.loaded = true;
            root.save();
        }
    }
}
