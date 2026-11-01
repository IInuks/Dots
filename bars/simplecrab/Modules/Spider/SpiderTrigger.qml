import QtQuick
import Quickshell
import "../.."

// Trigger-Widget in der Bar: oeffnet/schliesst SpiderMenu.qml als Popup
// direkt darunter, zeigt per Farbe an, ob der Spinnen-Modus gerade aktiv
// ist. Nutzt ein echtes Unicode-Emoji statt eines Nerd-Font-Glyphs -- die
// Bar hatte hier schon einmal Tofu-Boxen durch eine fehlende Nerd-Font-
// Installation (siehe README, "Bekannte Luecken"), ein Standard-Emoji
// haengt nicht an dieser Font ab.
Item {
    id: root

    required property ShellScreen screen
    property bool menuOpen: false

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "🕷" // U+1F577 SPIDER
        font.family: Colors.fontFamily
        font.pointSize: Colors.fontSize
        color: SpiderState.enabled ? Colors.accent : (root.menuOpen ? Colors.accentAlt : Colors.text)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    LazyLoader {
        active: root.menuOpen

        SpiderMenu {
            screen: root.screen
            onDismissed: root.menuOpen = false
        }
    }
}
