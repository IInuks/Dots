import QtQuick
import Quickshell
import Quickshell.Io
import "bar"

// Launcher-only host for bars/fisheye (see the menu README, "Launcher
// mischen"). fisheye's LauncherWindow normally hangs below its own bar's
// launcher button -- without that bar it's unanchored here, which centers
// it on the screen.
ShellRoot {
    id: host

    property bool open: false

    IpcHandler {
        target: "launcher"
        function toggle(): void { host.open = !host.open; }
        function open(): void { host.open = true; }
        function close(): void { host.open = false; }
    }

    Loader {
        active: host.open
        sourceComponent: LauncherWindow {
            modelData: Quickshell.screens.find(s => s.name === MangoIpc.focusedMonitorName) || Quickshell.screens[0]
            anchors.top: false
            anchors.left: false
            onCloseRequested: host.open = false
        }
    }
}
