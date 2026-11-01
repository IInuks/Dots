import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io


// Launcher-only host for bars/chamaeleon (see the menu README, "Launcher
// mischen"): chamaeleon's overlay window from shell.qml with only the launcher
// flyout in it -- no bar, no other flyouts, no notification server.
ShellRoot {
    id: root

    readonly property real _screenWidth: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920

    IpcHandler {
        target: "launcher"
        function toggle(): void { Popups.toggleAt("launcher", root._screenWidth / 2); }
        function open(): void { Popups.openAt("launcher", root._screenWidth / 2); }
        function close(): void { if (Popups.openId === "launcher") Popups.close(); }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "chamaeleon-launcher"
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
                color: Qt.rgba(0, 0, 0, 0.32)
                opacity: Popups.openId !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tMed } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Popups.close()
                }
            }

            Launcher { shown: Popups.isOpen("launcher"); screenWidthHint: root._screenWidth }
        }
    }
}
