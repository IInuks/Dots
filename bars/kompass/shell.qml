import Quickshell
import Quickshell.Io

ShellRoot {
    // External trigger for the mango keybind (SUPER+space, see README):
    // qs -p ~/quickdots/bars/kompass ipc call launcher toggle
    // LauncherState routes this to whichever Bar is on the focused monitor
    // -- see LauncherState.qml.
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherState.toggle();
        }
        function open(): void {
            LauncherState.open();
        }
        function close(): void {
            LauncherState.close();
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
}
