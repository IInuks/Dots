import QtQuick
import Quickshell
import Quickshell.Wayland

// Power icon that opens a small menu. The generic module contract (see
// ZoneContent.qml) gives modules no host-window/anchor-position handle, so
// unlike bar-specific power menus (which anchor under their own button) this
// one always opens as its own top-right overlay -- simplest thing that
// still works regardless of which zone/style the module ends up in.
Item {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    property bool menuOpen: false
    property string confirmAction: ""

    implicitWidth: 20
    implicitHeight: 20

    Text {
        anchors.centerIn: parent
        text: "⏻"
        font.pixelSize: root.fontSize + 2
        color: root.foreground
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    PanelWindow {
        visible: root.menuOpen
        anchors { top: true; right: true }
        margins { top: 40; right: 12 }
        implicitWidth: 170
        implicitHeight: col.implicitHeight + 16
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "custombar-power-menu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Qt.rgba(0.1, 0.1, 0.13, 0.95)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            Column {
                id: col
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2

                Repeater {
                    model: [
                        { key: "lock", label: "Sperren", danger: false },
                        { key: "suspend", label: "Standby", danger: false },
                        { key: "logout", label: "Abmelden", danger: false },
                        { key: "reboot", label: "Neustart", danger: true },
                        { key: "poweroff", label: "Herunterfahren", danger: true }
                    ]
                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        readonly property bool confirming: root.confirmAction === modelData.key
                        width: col.width
                        height: 28
                        radius: 6
                        color: hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: item.confirming ? "Sicher? " + item.modelData.label : item.modelData.label
                            font.pixelSize: 12
                            color: item.confirming ? "#ff8080" : root.foreground
                        }

                        MouseArea {
                            id: hover
                            property bool hovered: false
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: hovered = true
                            onExited: hovered = false
                            onClicked: {
                                if (!item.modelData.danger || item.confirming) {
                                    root._run(item.modelData.key);
                                    root.menuOpen = false;
                                    root.confirmAction = "";
                                } else {
                                    root.confirmAction = item.modelData.key;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function _run(key) {
        if (key === "lock") Quickshell.execDetached(["swaylock"]);
        else if (key === "suspend") Quickshell.execDetached(["systemctl", "suspend"]);
        else if (key === "logout") Quickshell.execDetached(["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") || ""]);
        else if (key === "reboot") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (key === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
