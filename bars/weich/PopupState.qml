pragma Singleton
import QtQuick

// Exclusivity for the popup cards (calendar / volume / settings): only one
// open at a time, identified by a plain string id.
QtObject {
    id: root

    property string openId: ""
    readonly property bool anyOpen: openId !== ""

    function isOpen(id) {
        return root.openId === id;
    }
    function toggle(id) {
        root.openId = (root.openId === id) ? "" : id;
    }
    function close() {
        root.openId = "";
    }
}
