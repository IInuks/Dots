import QtQuick
import Quickshell
import "../.."

// Power-Icon ganz rechts, oeffnet PowerMenu.qml als eigene kleine
// Overlay-Layer-Surface unterhalb des Icons (siehe dortigen Kommentar,
// warum kein In-Bar-Popup verwendet wird).
Item {
    id: root

    required property ShellScreen screen
    property bool menuOpen: false

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "\uf011" // nf-fa-power_off
        font.family: Colors.fontFamily
        font.pointSize: Colors.fontSize
        color: root.menuOpen ? Colors.accent : Colors.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    LazyLoader {
        active: root.menuOpen

        PowerMenu {
            screen: root.screen
            onDismissed: root.menuOpen = false
        }
    }
}
