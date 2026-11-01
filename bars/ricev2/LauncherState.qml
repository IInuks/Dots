pragma Singleton
import QtQuick

// Menus-prompt section 2: whether the app-launcher overlay is open, the
// active filter/search text, and which slice is selected. Root singleton
// for the same same-dir/pure-".." import reason as PowerMenuState.qml /
// DropdownState.qml (memory: feedback_quickshell_singleton_cross_dir_import).
QtObject {
    id: root

    property bool open: false
    property string filter: "all" // "all" | "apps" | "games" | "steam"
    property string searchText: ""
    property int selectedIndex: 0

    function show() {
        root.filter = "all";
        root.searchText = "";
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

    function setFilter(f) {
        if (root.filter === f)
            return;
        root.filter = f;
        root.selectedIndex = 0;
    }

    function typeText(t) {
        root.searchText += t;
        root.selectedIndex = 0;
    }

    function backspace() {
        if (root.searchText.length > 0) {
            root.searchText = root.searchText.slice(0, -1);
            root.selectedIndex = 0;
        }
    }

    // Clamped by the caller against the live filtered list length -- this
    // singleton doesn't know the list itself (AppIndex.filtered() is
    // recomputed live from Config/search state, not cached here).
    function moveBy(delta, count) {
        if (count <= 0)
            return;
        let next = root.selectedIndex + delta;
        if (next < 0)
            next = 0;
        if (next > count - 1)
            next = count - 1;
        root.selectedIndex = next;
    }
}
