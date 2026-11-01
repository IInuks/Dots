import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "test"

ShellRoot {
    // Review switch: true shows an isolated widget test scene instead of
    // the real bar (pick which one via the Loader below). false is the
    // normal state; flip to true only while iterating on a widget in
    // isolation, same as every stage so far.
    readonly property bool testMode: false

    // External trigger for mango's SUPER+space keybind:
    // qs -p ~/quickdots/bars/fisheye ipc call launcher toggle
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
        model: testMode ? [] : Quickshell.screens
        delegate: Bar {}
    }

    Loader {
        active: testMode
        sourceComponent: MenuTestScene {}
    }
}
