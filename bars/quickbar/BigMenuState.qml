pragma Singleton
import QtQuick

// Which tab of the big menu is active. A singleton (not local state inside
// BigMenu.qml) so any tab's content can jump to another tab -- e.g. the
// Control tab's message preview jumping to the Notifications tab.
QtObject {
    id: root

    property int activeTab: Settings.lastTab

    function selectTab(i) {
        root.activeTab = i;
        Settings.setLastTab(i);
    }
}
