//@ pragma ShellId 57ac85c5544fa8101527435a33904124
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Launcher-only host for bars/drop (see the menu README, "Launcher
// mischen"): drop's per-screen Overlay.qml with only the "Quelle" launcher
// in it -- no bar, no other menus, no OSD. Without a bar to hang from, the
// launcher drips in the middle of the screen without its neck.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggle("launcher", Mango.focusedMonitor, -1, 0); }
        function open(): void { Ui.open("launcher", Mango.focusedMonitor, -1, 0); }
        function close(): void { Ui.close(); }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property string screenName: modelData.name
            readonly property bool open: Ui.openId === "launcher" && Ui.screenName === screenName
            property bool lingering: false

            onOpenChanged: if (!open) { lingering = true; linger.restart(); }
            Timer { id: linger; interval: Theme.ms(420) + 80; onTriggered: win.lingering = false }

            visible: open || lingering
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "drop-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            FocusScope {
                id: scope
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Ui.close()

                MouseArea { anchors.fill: parent; onClicked: Ui.close() }
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: win.open && Settings.data.dim ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                }

                Launcher { screenName: win.screenName; screenWidth: win.width; focus: shown; hanging: false }
            }

            Connections {
                target: Ui
                function onOpenIdChanged() { if (win.open) scope.forceActiveFocus(); }
            }
        }
    }
}
