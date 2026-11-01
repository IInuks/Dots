pragma Singleton
import QtQuick

// Menus-prompt section 4: whether the power menu overlay is open, and
// which option is currently selected (arrow keys or hover). Root
// singleton for the same same-dir/pure-".." import reason as
// DropdownState.qml/Colors.qml (memory:
// feedback_quickshell_singleton_cross_dir_import).
QtObject {
    id: root

    property bool open: false
    property int selectedIndex: 0

    // Spec: "Beim Öffnen ist immer die erste Option ausgewählt."
    function show() {
        root.selectedIndex = 0;
        root.open = true;
    }
    function hide() {
        root.open = false;
    }
    function toggle() {
        if (root.open)
            root.hide();
        else
            root.show();
    }
}
