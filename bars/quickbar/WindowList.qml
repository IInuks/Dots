import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    readonly property var windows: MangoState.clientsOnActiveTag
    readonly property var shown: windows.slice(0, 3)
    readonly property int overflow: Math.max(0, windows.length - 3)

    implicitWidth: emptyLabel.visible ? emptyLabel.implicitWidth : row.implicitWidth
    implicitHeight: 24

    Text {
        id: emptyLabel
        visible: root.windows.length === 0
        anchors.verticalCenter: parent.verticalCenter
        text: "leer"
        color: Theme.textDim
        font.pixelSize: 12
        font.italic: true
    }

    Row {
        id: row
        visible: !emptyLabel.visible
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        add: Transition {
            NumberAnimation { properties: "scale"; from: 0; to: 1; duration: Theme.animMed; easing.type: Easing.OutBack }
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Theme.animFast }
        }

        Repeater {
            model: root.shown
            delegate: Rectangle {
                id: chip
                required property var modelData
                width: 22; height: 22
                radius: Theme.radiusSmall
                color: modelData.is_focused ? Theme.surfaceAlt : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    anchors.margins: 2
                    implicitSize: 16
                    source: Quickshell.hasThemeIcon(chip.modelData.appid)
                        ? Quickshell.iconPath(chip.modelData.appid)
                        : ""
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !Quickshell.hasThemeIcon(chip.modelData.appid)
                    text: (chip.modelData.appid || "?").charAt(0).toUpperCase()
                    color: Theme.text
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MangoState.focusClient(chip.modelData.id)
                }
            }
        }

        Rectangle {
            visible: root.overflow > 0
            width: 22; height: 22
            radius: Theme.radiusSmall
            color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "+" + root.overflow
                color: Theme.textDim
                font.pixelSize: 11
            }
        }
    }
}
