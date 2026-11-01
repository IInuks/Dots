import QtQuick
import Quickshell
import Quickshell.Io
import "core"
import "fold"
import "bar"
import "menus"
import "launcher"

// Faltwerk -- eine Origami-Shell fuer mango.
// Pro Bildschirm: eine Leiste (bar/Bar.qml) und ein unsichtbares Overlay
// (menus/Overlay.qml), in dem sich alle Menues und der Launcher auffalten.
ShellRoot {
    id: shell

    //   qs -p ~/quickdots/bars/faltwerk ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { Falt.toggle("launcher", Mango.focusedMonitor, -1); }
        function open(): void { Falt.open("launcher", Mango.focusedMonitor, -1); }
        function close(): void { Falt.close(); }
    }

    //   qs -p ~/quickdots/bars/faltwerk ipc call faltwerk toggle calendar
    //   (launcher | calendar | system | sound | paper | note | power)
    //   qs -p ~/quickdots/bars/faltwerk ipc call faltwerk paper tusche
    IpcHandler {
        target: "faltwerk"
        function toggle(menu: string): void { Falt.toggle(menu, Mango.focusedMonitor, -1); }
        function close(): void { Falt.close(); }
        function paper(name: string): void { Paper.request(name); }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Overlay {}
    }
}
