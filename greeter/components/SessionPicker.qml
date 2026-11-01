import QtQuick
import ".."

// Chip showing the current session; click opens a list above it (or below,
// with dropDown).
Item {
    id: root

    property int current: 0
    property bool open: false
    property bool dropDown: false
    property bool alignRight: false
    signal picked(int index)

    implicitWidth: chip.width
    implicitHeight: chip.height

    Rectangle {
        id: chip
        width: chipRow.implicitWidth + Theme.spacingL * 2
        height: Theme.chipHeight
        radius: height / 2
        color: chipMouse.containsMouse || root.open ? Theme.hover : Theme.panel
        border.color: root.open ? Qt.alpha(Theme.accent, 0.5) : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Theme.spacingS

            Text {
                text: ""
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontM
            }
            Text {
                text: Sessions.list[root.current]?.name ?? "No sessions"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontM
            }
            Text {
                text: ""
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontS
                anchors.verticalCenter: parent.verticalCenter
                rotation: (root.open ? 0 : 180) + (root.dropDown ? 180 : 0)
                Behavior on rotation { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }

    Rectangle {
        id: menu
        x: root.alignRight ? chip.width - width : 0
        y: root.dropDown ? chip.height + Theme.spacingS : -height - Theme.spacingS
        width: Math.max(chip.width, list.implicitWidth + Theme.spacingS * 2)
        height: list.implicitHeight + Theme.spacingS * 2
        radius: Theme.radiusSmall + 4
        color: Theme.panelSolid
        border.color: Theme.border
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: root.open ? 0 : (root.dropDown ? -8 : 8); Behavior on y { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMid } }

        Column {
            id: list
            anchors.centerIn: parent
            width: parent.width - Theme.spacingS * 2

            Repeater {
                model: Sessions.list
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    implicitWidth: label.implicitWidth + Theme.spacingL * 2 + 20
                    height: 34
                    radius: Theme.radiusSmall
                    color: rowMouse.containsMouse ? Theme.hover : "transparent"

                    Text {
                        id: label
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: index === root.current ? Theme.accent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontM
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        visible: index === root.current
                        text: ""
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.open = false;
                            root.picked(index);
                        }
                    }
                }
            }
        }
    }
}
