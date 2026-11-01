import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.menus

// Eine Ebene unter der Leiste, die alle Menüs trägt.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "polarlicht-menu"
    WlrLayershell.keyboardFocus: Hub.menu !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // bleibt sichtbar, bis die Schließ-Animation durch ist
    property bool lingering: false
    visible: Hub.menu !== "" || lingering
    Connections {
        target: Hub
        function onMenuChanged() {
            if (Hub.menu === "") { win.lingering = true; linger.restart() }
        }
    }
    Timer { id: linger; interval: Theme.dur(320) + 20; onTriggered: win.lingering = false }

    readonly property bool modal: ["launcher", "walls", "power"].includes(Hub.menu)

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Hub.close()

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Hub.menu === "" ? 0 : win.modal ? 0.35 : 0.08
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
        CalendarMenu {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
        }
        WindowsMenu {
            x: 10; y: 6
        }
        ControlCenter {
            anchors.right: parent.right; anchors.rightMargin: 10
            y: 6
        }
        SystemMenu {
            anchors.right: parent.right; anchors.rightMargin: 10
            y: 6
        }
        WallpaperMenu {
            anchors.centerIn: parent
        }
        PowerMenu {
            anchors.centerIn: parent
        }
    }
}
