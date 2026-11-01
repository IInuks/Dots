import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io


// Launcher-only host for bars/shellbar (see the menu README, "Launcher
// mischen"). The app list from shellbar's liquid clock menu (Launcher.qml) in a
// card of its own.
// Shown as a centered card on a fresh fullscreen surface per open (mango
// only grants keyboard focus reliably to a new surface).
ShellRoot {
    id: host

    property bool open: false

    IpcHandler {
        target: "launcher"
        function toggle(): void { host.open = !host.open; }
        function open(): void { host.open = true; }
        function close(): void { host.open = false; }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shellbar-launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
                MouseArea { anchors.fill: parent; onClicked: host.open = false }
            }

            Item {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.22)
                width: 420
                height: 460
                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                // Swallow clicks so the dim layer doesn't close on them.
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: Theme.surface
                    border.width: 1
                    border.color: Qt.alpha(Theme.foreground, 0.08)
                }
                Launcher {
                    anchors.fill: parent
                    anchors.margins: 14
                    onCloseRequested: host.open = false
                }
            }
        }
    }
}
