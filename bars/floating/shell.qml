import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "left"
import "center"
import "right"

ShellRoot {
    id: root

    // Quickshell itself owns notifications on this machine (spec 4
    // "Benachrichtigungsmenü") -- no mako/dunst/swaync running (confirmed via
    // `pgrep` before starting this build), so claiming the DBus name is
    // safe. actionsSupported is on since the spec explicitly wants
    // per-notification action buttons where present.
    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notif => {
            notif.tracked = true;
            NotificationState.push({
                id: notif.id,
                appName: notif.appName,
                appIcon: notif.appIcon,
                summary: notif.summary,
                body: notif.body,
                urgency: notif.urgency,
                actions: notif.actions || [],
                time: Qt.formatTime(new Date(), "hh:mm")
            }, notif);
            notif.closed.connect(() => NotificationState.removeOnly(notif.id));
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: TopGapReserve {}
    }
    Variants {
        model: Quickshell.screens
        delegate: LeftIsland {}
    }
    Variants {
        model: Quickshell.screens
        delegate: CenterIsland {}
    }
    Variants {
        model: Quickshell.screens
        delegate: RightIsland {}
    }

    Toast {}

    // Click-away dismissal for whichever popup is open, same technique as
    // quickbar/shell.qml and klasic/Bar.qml: a separate, permanently
    // click-through (when idle) fullscreen surface with zero exclusive
    // zone, so it never affects tiling.
    PanelWindow {
        id: catcher
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "floating-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: PopupState.anyOpen ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        MouseArea {
            anchors.fill: parent
            enabled: PopupState.anyOpen
            onClicked: PopupState.close()
        }
    }
}
