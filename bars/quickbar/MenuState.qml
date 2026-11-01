pragma Singleton
import QtQuick

// Which drop-menu (if any) is open. Only one at a time: opening a new one
// closes whatever else was open. shell.qml watches this to decide whether
// the panel window's input mask should cover just the bar shape (closed)
// or the whole screen (open, so outside clicks can be caught to close it).
QtObject {
    id: root

    property string openMenu: "" // "" | "power" | "launcher" | "big"

    function open(name) { root.openMenu = name; }
    function close() { root.openMenu = ""; }
    function toggle(name) { root.openMenu = (root.openMenu === name) ? "" : name; }
    readonly property bool anyOpen: root.openMenu !== ""
}
