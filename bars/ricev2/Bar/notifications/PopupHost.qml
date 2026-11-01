import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../"

// Menus-prompt section 5: the bar's own notification-popup daemon. Owns
// the NotificationServer -- it needs a stable app-lifetime owner rather
// than living inside a singleton, same split bars/claude/shell.qml uses
// for its own NotifyHub -- and renders the toast stack in its own small
// PanelWindow, independent of BarShell. Every incoming notification is
// pushed into PopupState (drives the on-screen toasts) and recorded into
// NotificationState (drives the "NOTIFICATIONS" dropdown's history, per
// spec's closing bullet).
Item {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: false

        onNotification: notif => {
            notif.tracked = true;
            const timeoutMs = notif.expireTimeout > 0 ? notif.expireTimeout : Style.popupDefaultTimeoutMs;
            PopupState.push({
                id: notif.id,
                notif: notif,
                appName: notif.appName || "",
                summary: notif.summary || "",
                body: notif.body || "",
                actions: notif.actions || [],
                timeoutMs: timeoutMs
            });
            NotificationState.record({
                ts: Date.now(),
                appName: notif.appName || "",
                summary: notif.summary || "",
                body: notif.body || "",
                timeText: Qt.formatTime(new Date(), "hh:mm")
            });
            notif.closed.connect(() => PopupState.remove(notif.id));
        }
    }

    PanelWindow {
        id: popupWindow

        readonly property bool leftSide: Config.notificationPopupSide === "left"

        screen: {
            const named = Quickshell.screens.find(s => s.name === Config.monitorName);
            return named ? named : Quickshell.screens[0];
        }

        WlrLayershell.namespace: "skwd-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.right: !popupWindow.leftSide
        anchors.left: popupWindow.leftSide
        margins.top: Style.popupTopMargin
        margins.right: popupWindow.leftSide ? 0 : Style.popupEdgeMargin
        margins.left: popupWindow.leftSide ? Style.popupEdgeMargin : 0

        color: "transparent"
        exclusiveZone: 0

        // Content-sized (only two anchors set), so there's nothing beyond
        // the stack itself in this window's geometry -- no mask needed
        // (unlike BarShell, which is wider/taller than its clickable
        // islands; see memory: feedback_quickshell_panelwindow_mask_input_region).
        visible: PopupState.queue.length > 0
        implicitWidth: Style.popupWidth
        implicitHeight: visible ? stack.implicitHeight : 1

        Column {
            id: stack
            width: parent.width
            spacing: Style.popupSpacing

            Repeater {
                model: PopupState.queue.slice(0, Style.popupMaxVisible)

                PopupCard {
                    required property var modelData
                    width: stack.width
                    entry: modelData
                    leftSide: popupWindow.leftSide
                }
            }
        }
    }
}
