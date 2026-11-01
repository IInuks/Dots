import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import "Bar"
import "Popups"

// A bottom dock (tags, five popup triggers, CPU/volume gauges, tray,
// clock) plus one full-screen overlay hosting five independent flyouts
// (launcher, wallpapers, quick settings, notifications, power) that each
// rise directly out of their own trigger icon, and a toast for incoming
// notifications. Palette adapts live from the current wallpaper via
// pywal. See README.md for the design rationale.
ShellRoot {
    id: root

    readonly property real _screenWidth: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920

    IpcHandler {
        target: "launcher"
        function toggle(): void { Popups.toggleAt("launcher", root._screenWidth / 2); }
        function open(): void { Popups.openAt("launcher", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "launcher") Popups.close(); }
    }
    IpcHandler {
        target: "wallpapers"
        function toggle(): void { Popups.toggleAt("wallpapers", root._screenWidth / 2); }
        function open(): void { Popups.openAt("wallpapers", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "wallpapers") Popups.close(); }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { Popups.toggleAt("settings", root._screenWidth / 2); }
        function open(): void { Popups.openAt("settings", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "settings") Popups.close(); }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { Popups.toggleAt("notifications", root._screenWidth / 2); }
        function open(): void { Popups.openAt("notifications", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "notifications") Popups.close(); }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { Popups.toggleAt("power", root._screenWidth / 2); }
        function open(): void { Popups.openAt("power", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "power") Popups.close(); }
    }
    IpcHandler {
        target: "volume"
        function toggle(): void { Popups.toggleAt("volume", root._screenWidth / 2); }
        function open(): void { Popups.openAt("volume", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "volume") Popups.close(); }
    }
    IpcHandler {
        target: "monitor"
        function toggle(): void { Popups.toggleAt("monitor", root._screenWidth / 2); }
        function open(): void { Popups.openAt("monitor", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "monitor") Popups.close(); }
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notif => {
            notif.tracked = true;
            NotifyHub.receive({
                id: notif.id,
                app: notif.appName,
                icon: notif.appIcon,
                title: notif.summary,
                body: notif.body,
                stamp: Qt.formatTime(new Date(), "hh:mm")
            }, notif);
            notif.closed.connect(() => NotifyHub.forget(notif.id));
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    PanelWindow {
        id: overlayWin
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "claude-overlay"
        WlrLayershell.keyboardFocus: Popups.openId !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: Popups.openId !== "" ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        FocusScope {
            anchors.fill: parent
            focus: Popups.openId !== ""
            Keys.onEscapePressed: Popups.close()

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.38)
                opacity: Popups.openId !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Chroma.tMed } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Popups.close()
                }
            }

            Launcher { shown: Popups.isOpen("launcher"); screenWidthHint: root._screenWidth }
            Wallpapers { shown: Popups.isOpen("wallpapers"); screenWidthHint: root._screenWidth }
            QuickSettings { shown: Popups.isOpen("settings"); screenWidthHint: root._screenWidth }
            NotificationsPanel { shown: Popups.isOpen("notifications"); screenWidthHint: root._screenWidth }
            PowerPanel { shown: Popups.isOpen("power"); screenWidthHint: root._screenWidth }
            VolumePanel { shown: Popups.isOpen("volume"); screenWidthHint: root._screenWidth }
            SystemMonitor { shown: Popups.isOpen("monitor"); screenWidthHint: root._screenWidth }

            Toast {}
        }
    }
}
