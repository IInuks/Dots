pragma Singleton
import QtQuick
import Quickshell

// Which popup is open, on which screen, anchored at which x.
// Only one popup is open at a time across all screens.
//
// ids: launcher, control, studio, calendar, system, media, notifications,
//      session
Singleton {
    id: root

    property string openId: ""
    property string screenName: ""
    property real anchorX: 0

    function isOpen(id, screen) {
        return root.openId === id && root.screenName === screen;
    }

    function open(id, screen, x) {
        root.screenName = screen || (Quickshell.screens[0] ? Quickshell.screens[0].name : "");
        root.anchorX = x === undefined ? -1 : x;
        root.openId = id;
    }

    function toggle(id, screen, x) {
        if (root.openId === id && (!screen || root.screenName === screen))
            root.close();
        else
            root.open(id, screen, x);
    }

    function close() {
        root.openId = "";
    }
}
