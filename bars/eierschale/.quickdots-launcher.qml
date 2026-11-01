//@ pragma ShellId f3f1b402da89b7bd3488c5934ca7008b
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Launcher-only host for bars/eierschale (see the menu README, "Launcher
// mischen"): eierschale's per-screen Overlay.qml with only the "Nest"
// launcher in it -- no bar, no other popups, no OSD.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggle("launcher", Mango.focusedMonitor, -1); }
        function open(): void { Ui.open("launcher", Mango.focusedMonitor, -1); }
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
            Timer { id: linger; interval: Theme.tMed + 80; onTriggered: win.lingering = false }

            visible: open || lingering
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "eierschale-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            FocusScope {
                id: scope
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Ui.close()

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: win.open && Settings.data.dim ? 0.45 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                    MouseArea { anchors.fill: parent; onClicked: Ui.close() }
                }

                Launcher { screenName: win.screenName; screenWidth: win.width; focus: shown }
            }

            Connections {
                target: Ui
                function onOpenIdChanged() { if (win.open) scope.forceActiveFocus(); }
            }
        }
    }
}
