import QtQuick
import Quickshell
import ".."

// Shutdown/Reboot/Logout/Lock with inline confirm-or-cancel for the
// destructive ones. Actions verified against this exact compositor
// (mango) in bars/fullshell/PowerTab.qml -- reused 1:1, not guessed:
// logout goes through `mmsg dispatch quit` (mango's own IPC), not
// loginctl, and lock uses swaylock like the rest of the user's setup.
Item {
    id: root

    signal actionRun

    readonly property var actions: [
        {
            key: "lock",
            label: "SPERREN",
            danger: false,
            confirm: false
        },
        {
            key: "logout",
            label: "ABMELDEN",
            danger: false,
            confirm: false
        },
        {
            key: "restart",
            label: "NEUSTART",
            danger: true,
            confirm: true
        },
        {
            key: "poweroff",
            label: "HERUNTERFAHREN",
            danger: true,
            confirm: true
        }
    ]

    function run(key) {
        if (key === "lock")
            Quickshell.execDetached(["swaylock"]);
        else if (key === "logout")
            Quickshell.execDetached(["mmsg", "dispatch", "quit"]);
        else if (key === "restart")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (key === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
        root.actionRun();
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.actions

            Rectangle {
                id: btn
                required property var modelData
                property bool confirming: false

                width: parent.width
                height: 30
                radius: Theme.radius * 0.6
                color: hoverArea.containsMouse ? Qt.alpha(btn.modelData.danger ? Theme.critical : Theme.accent, 0.18) : "transparent"
                border.width: 1
                border.color: Theme.bevelDark
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durFast
                    }
                }

                Timer {
                    id: confirmTimeout
                    interval: 4000
                    onTriggered: btn.confirming = false
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.modelData.label
                    color: btn.modelData.danger ? Theme.critical : Theme.surfaceInk
                    font.pixelSize: 10
                    font.letterSpacing: 0.5
                    opacity: btn.confirming ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    opacity: btn.confirming ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }

                    Text {
                        text: "SICHER?"
                        color: Theme.surfaceInk
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 26
                        height: 18
                        radius: Theme.radius * 0.5
                        color: Theme.critical
                        Text {
                            anchors.centerIn: parent
                            text: "JA"
                            color: Theme.accentInk
                            font.pixelSize: 9
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(btn.modelData.key)
                        }
                    }
                    Rectangle {
                        width: 26
                        height: 18
                        radius: Theme.radius * 0.5
                        color: Theme.bevelDark
                        Text {
                            anchors.centerIn: parent
                            text: "NEIN"
                            color: Theme.surfaceInk
                            font.pixelSize: 8
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btn.confirming = false
                        }
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !btn.confirming
                    onClicked: {
                        if (btn.modelData.confirm) {
                            btn.confirming = true;
                            confirmTimeout.restart();
                        } else {
                            root.run(btn.modelData.key);
                        }
                    }
                }
            }
        }
    }
}
