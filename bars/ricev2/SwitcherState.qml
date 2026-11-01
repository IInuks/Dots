pragma Singleton
import QtQuick

// Menus-prompt section 3: window-switcher overlay state. `windows` is a
// one-shot snapshot fetched via `mmsg get all-clients` when the overlay
// opens (see Bar/switcher/Switcher.qml's Process) -- NOT a live `mmsg
// watch all-clients` subscription like bars/quickbar/MangoState.qml,
// since a mid-selection reshuffle from some unrelated window opening or
// closing elsewhere would be jarring for an Alt-Tab-style picker. Root
// singleton for the same same-dir/pure-".." import reason as
// LauncherState.qml/PowerMenuState.qml (memory:
// feedback_quickshell_singleton_cross_dir_import).
QtObject {
    id: root

    property bool open: false
    property var windows: [] // [{id, title, appid, tags, is_focused, is_floating, ...}, ...]
    property int selectedIndex: 0

    function moveBy(delta) {
        const n = root.windows.length;
        if (n <= 0)
            return;
        let next = (root.selectedIndex + delta) % n;
        if (next < 0)
            next += n;
        root.selectedIndex = next;
    }

    // Optimistic local removal after a `close` dispatch -- see
    // Switcher.qml's _closeSelected() for why this isn't re-fetched from
    // mmsg.
    function removeSelected() {
        const idx = root.selectedIndex;
        if (idx < 0 || idx >= root.windows.length)
            return;
        const next = root.windows.slice();
        next.splice(idx, 1);
        root.windows = next;
        if (root.selectedIndex >= root.windows.length)
            root.selectedIndex = Math.max(0, root.windows.length - 1);
    }
}
