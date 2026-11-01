import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets

// Launcher-only host for bars/quickbar (see the menu README, "Launcher
// mischen"). quickbar's search pill (Launcher.qml) and its drop-down results
// (LauncherResults.qml), stacked in one card instead of hanging off the bar.
// Shown as a centered card on a fresh fullscreen surface per open (mango
// only grants keyboard focus reliably to a new surface).
ShellRoot {
    id: host

    property bool open: false
    onOpenChanged: { if (open) MenuState.open("launcher"); else MenuState.close(); }

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
            WlrLayershell.namespace: "quickbar-launcher"
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
                width: 340
                height: column.implicitHeight + 24
                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                // Swallow clicks so the dim layer doesn't close on them.
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusLarge
                    color: Theme.bg
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.08)
                }
                Column {
                    id: column
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 10
                    Launcher {
                        id: launcher
                        anchors.horizontalCenter: parent.horizontalCenter
                        Connections {
                            target: MenuState
                            function onOpenMenuChanged() { if (MenuState.openMenu !== "launcher") host.open = false; }
                        }
                    }
                    Text {
                        visible: launcher.results.length === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: launcher.query.length === 0 ? "Tippen zum Suchen…" : "Keine Treffer"
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.italic: true
                    }
                    LauncherResults {
                        width: parent.width
                        results: launcher.results
                        query: launcher.query
                        selectedIndex: launcher.selectedIndex
                    }
                }
            }
        }
    }
}
