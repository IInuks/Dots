import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // Lets a keybind (e.g. mango's SUPER+space) open the launcher instead
    // of hovering the clock: `qs -p ~/shellbar ipc call launcher toggle`.
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherState.pinned = !LauncherState.pinned;
        }
    }
}
