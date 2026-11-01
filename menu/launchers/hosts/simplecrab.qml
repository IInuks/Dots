import QtQuick
import Quickshell
import Quickshell.Io
import "Modules/Launcher"

// Launcher-only host for bars/simplecrab (see the
// menu README, "Launcher mischen"): simplecrab's own shell.qml minus the bar.
ShellRoot {
    id: host

    property bool launcherOpen: false

    function _focusedScreen() {
        const name = MangoIpc.focusedMonitorName;
        return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0];
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { host.launcherOpen = !host.launcherOpen; }
        function open(): void { host.launcherOpen = true; }
        function close(): void { host.launcherOpen = false; }
    }

    LazyLoader {
        active: host.launcherOpen

        Launcher {
            screen: host._focusedScreen()
            onDismissed: host.launcherOpen = false
        }
    }
}
