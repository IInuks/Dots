pragma Singleton
import QtQuick

// Central open/close state for the Bars-switch menu panel.
QtObject {
    id: root

    property bool visible: false

    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
    function toggle(): void { root.visible = !root.visible; }
}
