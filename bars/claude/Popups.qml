pragma Singleton
import QtQuick

// Which single flyout is currently open (each dock button owns one:
// "launcher" | "wallpapers" | "settings" | "notifications" | "power"),
// plus the screen-x it should hover above -- captured once, at the moment
// its trigger is clicked, so every popup appears to rise directly out of
// its own icon instead of always popping up in one fixed, central spot.
QtObject {
    id: root

    property string openId: ""
    property real anchorX: 0
    property int focusToken: 0

    function isOpen(id) { return root.openId === id; }

    function openAt(id, x) {
        root.anchorX = x;
        root.openId = id;
        root.focusToken++;
    }

    function toggleAt(id, x) {
        if (root.openId === id) {
            root.openId = "";
            return;
        }
        root.openAt(id, x);
    }

    function close() { root.openId = ""; }
}
