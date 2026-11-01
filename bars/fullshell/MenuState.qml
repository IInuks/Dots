pragma Singleton
import QtQuick

// The Command Center is one overlay with 5 tabs rather than separate
// popups -- open/closed plus which tab is showing.
QtObject {
    id: root

    readonly property int tabApps: 0
    readonly property int tabWallpaper: 1
    readonly property int tabDesign: 2
    readonly property int tabSystem: 3
    readonly property int tabPower: 4

    property bool open: false
    property int activeTab: Settings.lastTab
    // Bumped every time the Apps tab is force-opened via IPC, so
    // ApplicationsTab can re-focus its search field even if that tab was
    // already showing.
    property int focusSearchToken: 0

    function selectTab(i) {
        root.activeTab = i;
        Settings.setLastTab(i);
    }

    function openAt(tab) {
        root.selectTab(tab);
        root.open = true;
    }

    function toggleAt(tab) {
        if (root.open && root.activeTab === tab) { root.open = false; return; }
        root.openAt(tab);
    }

    function close() { root.open = false; }

    function toggleDefault() {
        if (root.open) { root.open = false; return; }
        root.openAt(root.activeTab);
    }

    function openLauncher() {
        root.openAt(root.tabApps);
        root.focusSearchToken++;
    }

    function openWallpaper() { root.openAt(root.tabWallpaper); }
}
