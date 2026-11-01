//@ pragma ShellId 7dc232944f2430097a7349b243c902b9
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.menus

// Launcher-only host for bars/polarlicht (see the menu README, "Launcher
// mischen"): polarlicht's Overlay.qml with only the launcher card in it.
// Hub.menu is shared with nothing else here, so "launcher" is the only
// value it ever takes.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { Hub.toggle("launcher"); }
        function open(): void { Hub.open("launcher"); }
        function close(): void { Hub.close(); }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "polarlicht-launcher"
        WlrLayershell.keyboardFocus: Hub.menu !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property bool lingering: false
        visible: Hub.menu !== "" || lingering
        Connections {
            target: Hub
            function onMenuChanged() {
                if (Hub.menu === "") { win.lingering = true; linger.restart() }
            }
        }
        Timer { id: linger; interval: Theme.dur(320) + 20; onTriggered: win.lingering = false }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Hub.close()

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: Hub.menu === "" ? 0 : 0.35
                Behavior on opacity { NumberAnimation { duration: Theme.dur(300) } }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: Hub.close()
            }

            Launcher {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.1
            }
        }
    }
}
