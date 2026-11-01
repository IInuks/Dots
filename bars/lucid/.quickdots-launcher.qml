//@ pragma ShellId d2606e89c89e4de6d493275abb6fdc01
import QtQuick
import Quickshell
import Quickshell.Io

// Launcher-only host for bars/lucid (see the menu README, "Launcher
// mischen"): lucid's own shell.qml minus the bar, panels and notifications.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle(); }
        function open(): void { LauncherState.open(); }
        function close(): void { LauncherState.close(); }
    }

    Loader {
        active: LauncherState.isOpen
        sourceComponent: LauncherWindow {
            screenName: LauncherState.screenName
            onCloseRequested: LauncherState.close()
        }
    }
}
