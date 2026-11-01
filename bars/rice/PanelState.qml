pragma Singleton
import QtQuick

// Which bottom-sheet panel is open, if any: "" | "controlcenter" |
// "wallpapers" | "power". At most one at a time -- opening a second closes
// the first (PanelSheet.qml's own visibility binding handles that, this
// singleton just holds the one id).
QtObject {
    id: root

    property string openPanel: ""

    function toggle(id) { root.openPanel = root.openPanel === id ? "" : id; }
    function open(id) { root.openPanel = id; }
    function close() { root.openPanel = ""; }
}
