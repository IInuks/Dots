import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

// Eigene kleine Overlay-Layer-Surface statt eines In-Bar-Popups: die Bar
// selbst ist exakt Settings.barHeight hoch (kein Extra-Platz fuer ein nach
// unten aufklappendes Menue reserviert), und ein Quickshell-Fenster kann
// grundsaetzlich nichts ausserhalb seiner eigenen Surface-Groesse zeichnen.
//
// Fenster spannt (wie Launcher.qml) den gesamten Bildschirm transparent auf;
// das sichtbare Menue ist oben rechts positioniert. Mango hat keinen
// Focus-Grab-Mechanismus wie Hyprland -- ein Klick auf den transparenten
// Rand schliesst das Menue stattdessen einfach ueber eine Vollbild-
// MouseArea.
PanelWindow {
    id: root

    required property ShellScreen screen
    signal dismissed

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simple-powermenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: menuBox
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Settings.barHeight + 4
        anchors.rightMargin: 8
        width: Settings.powerMenuWidth
        height: actions.count * Settings.powerMenuItemHeight + 8
        color: Colors.panel

        // Absorbiert Klicks auf den Menue-Hintergrund, damit sie nicht als
        // "Klick ausserhalb" bei der Vollbild-MouseArea darunter zaehlen.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ListView {
            id: actions
            anchors.fill: parent
            anchors.margins: 4
            interactive: false

            model: [
                {
                    label: "Sperren",
                    command: Settings.lockCommand
                },
                {
                    label: "Logout",
                    command: Settings.logoutCommand
                },
                {
                    label: "Reboot",
                    command: Settings.rebootCommand
                },
                {
                    label: "Shutdown",
                    command: Settings.shutdownCommand
                }
            ]

            delegate: Rectangle {
                required property var modelData

                width: actions.width
                height: Settings.powerMenuItemHeight
                color: entryArea.containsMouse ? Colors.panelAlt : "transparent"

                Text {
                    text: parent.modelData.label
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Colors.fontFamily
                    font.pointSize: Colors.fontSize
                    font.letterSpacing: Colors.letterSpacing
                    color: Colors.text
                }

                MouseArea {
                    id: entryArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", parent.modelData.command]);
                        root.dismissed();
                    }
                }
            }
        }
    }
}
