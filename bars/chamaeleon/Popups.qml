pragma Singleton
import QtQuick

// Which flyout is open, and the x position it should rise from (the
// trigger's own screen position, captured via mapToItem at click time).
// Stage 1 only ever has one popup ("settings") but the API stays generic
// so later stages (launcher, wallpapers, ...) don't need a rewrite.
QtObject {
    id: root

    property string openId: ""
    property real anchorX: 0
    // Bumped every time a popup opens -- popups with a text field watch
    // this via Connections to force keyboard focus back onto themselves.
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
        } else {
            root.anchorX = x;
            root.openId = id;
            root.focusToken++;
        }
    }

    function close() { root.openId = ""; }
}
