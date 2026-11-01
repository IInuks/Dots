pragma Singleton
import QtQuick

// Shared open/close flag for the app launcher (Clock's liquid menu),
// toggled by mango's SUPER+space keybind via shell.qml's IpcHandler
// instead of only by hovering the clock.
QtObject {
    property bool pinned: false
}
