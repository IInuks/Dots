import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "Bar"

// Root. One Bar per connected screen -- Config decides per-module which
// screens actually show a pill (Config.moduleVisibleOn), Bar.qml itself is
// still instantiated everywhere so a module with monitor:"" (every screen)
// works without a restart when a monitor is (dis)connected.
//
// IPC targets (`qs -p <this dir> ipc call -- <target> <function>`), routed
// via BarRegistry to whichever screen's bar is on the currently-focused
// monitor: one IpcHandler per module, added as each module's own build
// stage lands real functionality behind it.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle(); }
        function open(): void { LauncherState.open(); }
        function close(): void { LauncherState.close(); }
    }

    // Fresh LauncherWindow per open, not an always-mapped window with
    // `visible` bound to isOpen -- see LauncherWindow.qml's own comment
    // for why a genuinely new surface is required every time.
    Loader {
        active: LauncherState.isOpen
        sourceComponent: LauncherWindow {
            screenName: LauncherState.screenName
            onCloseRequested: LauncherState.close()
        }
    }

    IpcHandler {
        target: "tags"
        function toggle(): void { BarRegistry.toggle("tags"); }
        function open(): void { BarRegistry.open("tags"); }
        function close(): void { BarRegistry.close("tags"); }
    }

    IpcHandler {
        target: "clock"
        function toggle(): void { BarRegistry.toggle("clock"); }
        function open(): void { BarRegistry.open("clock"); }
        function close(): void { BarRegistry.close("clock"); }
    }

    IpcHandler {
        target: "system"
        function toggle(): void { BarRegistry.toggle("system"); }
        function open(): void { BarRegistry.open("system"); }
        function close(): void { BarRegistry.close("system"); }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { BarRegistry.toggle("media"); }
        function open(): void { BarRegistry.open("media"); }
        function close(): void { BarRegistry.close("media"); }
    }

    IpcHandler {
        target: "tray"
        function toggle(): void { BarRegistry.toggle("tray"); }
        function open(): void { BarRegistry.open("tray"); }
        function close(): void { BarRegistry.close("tray"); }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { BarRegistry.toggle("notifications"); }
        function open(): void { BarRegistry.open("notifications"); }
        function close(): void { BarRegistry.close("notifications"); }
    }

    // No mako/dunst/swaync/fnott running on this machine (checked via
    // pgrep before wiring this up), so claiming org.freedesktop.
    // Notifications here is safe. actionsSupported on since the panel
    // renders per-notification action buttons; imageSupported off since
    // Stage 5's scope is Toasts/History/DND/Actions, no icon rendering
    // (same deliberate scope line already drawn for the System/Tray pill
    // icons -- see README "Bekannte Lücken").
    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true

        onNotification: notif => {
            notif.tracked = true;
            NotificationState.receive({
                id: notif.id,
                app: notif.appName,
                title: notif.summary,
                body: notif.body,
                actions: notif.actions || [],
                stamp: Qt.formatTime(new Date(), "hh:mm")
            }, notif);
            notif.closed.connect(() => NotificationState.forget(notif.id));
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
}
