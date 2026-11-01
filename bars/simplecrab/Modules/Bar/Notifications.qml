import QtQuick
import "../.."

// Benachrichtigungs-Icon: Klick toggelt Do-Not-Disturb (reiner UI-Zustand,
// siehe Kommentar bei Settings.dndEnabled -- Quickshell selbst kennt keinen
// globalen DND-Schalter).
Text {
    text: Settings.dndEnabled ? "\uf1f6" : "\uf0f3" // nf-fa-bell_slash / nf-fa-bell
    font.family: Colors.fontFamily
    font.pointSize: Colors.fontSize
    color: Settings.dndEnabled ? Colors.accent : Colors.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Settings.dndEnabled = !Settings.dndEnabled
    }
}
