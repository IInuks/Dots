//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "components"
import "services"
import "modules/bar"
import "modules/launcher"
import "modules/controlcenter"
import "modules/widgets"
import "modules/notifications"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        Desktop {}
    }

    Launcher {}
    ControlCenter {}
    PowerMenu {}
    CalendarPopup {}
    Toasts {}

    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggleLauncher(); }
        function open(): void { Ui.closeAll(); Ui.launcherOpen = true; }
        function close(): void { Ui.launcherOpen = false; }
    }
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { Ui.toggleControlCenter(""); }
        function page(name: string): void { Ui.toggleControlCenter(name); }
        function close(): void { Ui.controlCenterOpen = false; }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { Ui.togglePower(); }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void { Ui.toggleCalendar(); }
    }
    IpcHandler {
        target: "notifications"
        function test(): void { Notifs.test(); }
        function clear(): void { Notifs.clear(); }
        function dnd(): void { Ui.dnd = !Ui.dnd; }
    }
}
