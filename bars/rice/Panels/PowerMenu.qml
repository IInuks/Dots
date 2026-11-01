import QtQuick
import "../"
import "../Bar"

// Lock/Logout/Reboot/Shutdown -- MangoService.lock()/logout()/reboot()/
// shutdown() (swaylock, `mmsg dispatch quit`, systemctl reboot/poweroff --
// the last matches the SUPER+SHIFT+BackSpace keybind already in
// mango-config.conf today).
PanelSheet {
    id: root
    open: PanelState.openPanel === "power"
    sheetWidth: 260
    sheetHeight: 240
    horizontalAlign: "right"

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Repeater {
            model: [
                { label: "Sperren", glyph: "lock", fn: "lock" },
                { label: "Abmelden", glyph: "logout", fn: "logout" },
                { label: "Neu starten", glyph: "restart_alt", fn: "reboot" },
                { label: "Herunterfahren", glyph: "power_settings_new", fn: "shutdown" }
            ]
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: 44
                radius: Theme.tileRadius
                color: hoverArea.containsMouse ? Theme.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Icon {
                        glyph: modelData.glyph
                        fallback: modelData.label.charAt(0)
                        size: 18
                        tint: modelData.fn === "shutdown" ? Theme.urgent : Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.label
                        color: modelData.fn === "shutdown" ? Theme.urgent : Theme.text
                        font.family: Theme.uiFontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        PanelState.close();
                        if (modelData.fn === "lock") MangoService.lock();
                        else if (modelData.fn === "logout") MangoService.logout();
                        else if (modelData.fn === "reboot") MangoService.reboot();
                        else if (modelData.fn === "shutdown") MangoService.shutdown();
                    }
                }
            }
        }
    }
}
