pragma Singleton
import QtQuick

// Relais zwischen dem globalen IpcHandler (shell.qml, ein Aufruf pro
// mmsg-Hotkey) und der einen Bar-Instanz, die gerade den fokussierten
// Monitor zeigt (Mango.focusedMonitorName) -- gleiches Prinzip wie
// bars/fisheye/LauncherState.qml. Root-level Singleton, siehe Theme.qml.
QtObject {
    signal togglePulse
    signal openPulse
    signal closePulse

    function toggle() {
        togglePulse();
    }
    function open() {
        openPulse();
    }
    function close() {
        closePulse();
    }
}
