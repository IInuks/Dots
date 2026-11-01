import Quickshell
import Quickshell.Io

ShellRoot {
    // Externer Trigger fuer den Mango-Keybind (siehe README fuer die
    // config.conf-Zeile): qs -p ~/quickdots/bars/blobs ipc call
    // launcher toggle. LauncherState routet das an die Bar auf dem
    // fokussierten Monitor -- siehe LauncherState.qml.
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
