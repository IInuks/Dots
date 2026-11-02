//@ pragma ShellId 4b958d8f8a4efb2d11c50022add7a252
import QtQuick
import Quickshell
import Quickshell.Io

// Launcher-only host for bars/kompass (see the menu README, "Launcher
// mischen"): the fresh-per-open LauncherWindow from Bar.qml, without the bar.
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
            onCloseRequested: host.open = false
        }
    }
}
