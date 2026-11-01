import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import "Bar"

// ksp -- "Mission Control" top bar for mango, styled after Kerbal Space
// Program's UI (hazard-stripe accents, HUD corner brackets, chronometer,
// staging-style tag badges) with three animated flyouts: launcher, comms
// log (notifications), control center. See README.md for the design
// rationale and staged roadmap.
ShellRoot {
    id: root

    readonly property real _screenWidth: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920

    IpcHandler {
        target: "settings"
        function toggle(): void { Popups.toggleAt("settings", root._screenWidth / 2); }
        function open(): void { Popups.openAt("settings", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "settings") Popups.close(); }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Popups.toggleAt("launcher", root._screenWidth / 2); }
        function open(): void { Popups.openAt("launcher", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "launcher") Popups.close(); }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { Popups.toggleAt("notifications", root._screenWidth / 2); }
        function open(): void { Popups.openAt("notifications", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "notifications") Popups.close(); }
    }
    IpcHandler {
        target: "telemetry"
        function toggle(): void { Popups.toggleAt("telemetry", root._screenWidth / 2); }
        function open(): void { Popups.openAt("telemetry", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "telemetry") Popups.close(); }
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
        WlrLayershell.namespace: "ksp-overlay"
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
                color: Qt.rgba(0, 0, 0, 0.35)
                opacity: Popups.openId !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tMed } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Popups.close()
                }
            }

            ControlCenter { shown: Popups.isOpen("settings"); screenWidthHint: root._screenWidth }
            Launcher { shown: Popups.isOpen("launcher"); screenWidthHint: root._screenWidth }
            Notifications { shown: Popups.isOpen("notifications"); screenWidthHint: root._screenWidth }
            Telemetry { shown: Popups.isOpen("telemetry"); screenWidthHint: root._screenWidth }
        }
    }
}
