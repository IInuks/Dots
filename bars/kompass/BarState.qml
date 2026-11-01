pragma Singleton
import QtQuick

// Central open/closed state for popup panels (Etappe 6-8: audio, network,
// power). Kept as one enum-like string, not scattered per-component
// booleans, same convention as bars/blobs/BarState.qml.
QtObject {
    id: root

    property string active: "none" // "none" | "audio" | "network" | "power"

    function toggle(name) {
        root.active = root.active === name ? "none" : name;
    }
    function close() {
        root.active = "none";
    }
}
