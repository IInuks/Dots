pragma Singleton
import QtQuick

// Which popup is open, shared across all three island windows so "only one
// popup at a time" (spec 4, "Für alle Popups gilt") holds regardless of
// which island it belongs to. Each island window decides its own
// implicitHeight/keyboardFocus off of `openPopup` -- see IslandBase.qml.
QtObject {
    id: root

    // "" | "monitor" | "calendar" | "notifications" | "audio" | "power"
    property string openPopup: ""
    readonly property bool anyOpen: openPopup !== ""

    function toggle(name) {
        root.openPopup = root.openPopup === name ? "" : name;
    }
    function close() {
        root.openPopup = "";
    }
}
