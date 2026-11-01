pragma Singleton
import QtQuick

// Bridges the mango keybind's IPC call (shell.qml's IpcHandler) to whichever
// Bar instance is on the focused monitor -- there's one Bar per screen
// (Variants in shell.qml), each with its own local `openPopup`, so a global
// toggle can't just flip a single shared bool the way a one-window shell
// would. A signal pulse instead: every Bar listens via Connections and only
// the one whose outputName matches MangoIpc.focusedMonitorName actually
// opens/closes its own popup.
QtObject {
    id: root

    signal togglePulse
    signal openPulse
    signal closePulse

    function toggle() {
        root.togglePulse();
    }
    function open() {
        root.openPulse();
    }
    function close() {
        root.closePulse();
    }
}
