import QtQuick
import Quickshell

Column {
    id: root
    anchors.fill: parent
    spacing: 12

    readonly property var actions: [
        { key: "lock", label: "Sperren", icon: "lock", danger: false, confirm: false },
        { key: "logout", label: "Abmelden", icon: "logout", danger: false, confirm: false },
        { key: "restart", label: "Neustarten", icon: "restart", danger: false, confirm: true },
        { key: "poweroff", label: "Herunterfahren", icon: "power", danger: true, confirm: true }
    ]

    function run(key) {
        if (key === "lock") Quickshell.execDetached(["swaylock"]);
        else if (key === "logout") Quickshell.execDetached(["mmsg", "dispatch", "quit"]);
        else if (key === "restart") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (key === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Item { width: 1; height: 4 }

    Repeater {
        model: root.actions
        delegate: Rectangle {
            id: btn
            required property var modelData
            property bool confirming: false

            width: parent.width
            height: 56
            radius: Theme.radiusMed
            color: hoverArea.containsMouse ? Qt.alpha(btn.modelData.danger ? Theme.danger : Theme.accent, 0.14) : Theme.surfaceAlt
            Behavior on color { ColorAnimation { duration: Theme.animMed } }

            Timer {
                id: confirmTimeout
                interval: 4000
                onTriggered: btn.confirming = false
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                opacity: btn.confirming ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: btn.modelData.icon
                    size: 18
                    tint: btn.modelData.danger ? Theme.danger : Theme.text
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.modelData.label
                    color: Theme.text
                    font.pixelSize: 14
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 16
                opacity: btn.confirming ? 1 : 0
                scale: btn.confirming ? 1 : 0.85
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.4 } }

                Text { text: "Wirklich " + btn.modelData.label.toLowerCase() + "?"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }

                Rectangle {
                    width: 60; height: 30; radius: Theme.radiusSmall
                    color: Theme.danger
                    Text { anchors.centerIn: parent; text: "Ja"; color: "white"; font.pixelSize: 12; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.run(btn.modelData.key); MenuState.close(); } }
                }
                Rectangle {
                    width: 90; height: 30; radius: Theme.radiusSmall
                    color: Theme.surface
                    border.width: 1; border.color: Theme.textDim
                    Text { anchors.centerIn: parent; text: "Abbrechen"; color: Theme.textDim; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btn.confirming = false }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !btn.confirming
                onClicked: {
                    if (btn.modelData.confirm) { btn.confirming = true; confirmTimeout.restart(); }
                    else { root.run(btn.modelData.key); MenuState.close(); }
                }
            }
        }
    }
}
