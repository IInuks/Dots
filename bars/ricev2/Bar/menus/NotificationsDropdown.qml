import QtQuick
import "../../"

// Notification center content (menus prompt 1.6). Reads NotificationState,
// populated by ricev2's own popup daemon (Bar/notifications/PopupHost.qml,
// menus prompt section 5, Stage 5).
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 8

    Item {
        width: parent.width
        height: 22

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Text {
                font.family: Style.textFont
                font.pixelSize: Style.fontSubtitle
                color: Colors.primary
                text: "NOTIFICATIONS"
            }
            Text {
                font.family: Style.textFont
                font.pixelSize: 11
                opacity: 0.6
                color: Colors.tertiary
                text: String(NotificationState.count)
            }
        }

        Rectangle {
            visible: NotificationState.count > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: clearLabel.implicitWidth + 16
            height: 22
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)

            Text {
                id: clearLabel
                anchors.centerIn: parent
                font.family: Style.textFont
                font.pixelSize: 10
                color: Colors.primary
                text: "CLEAR ALL"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: NotificationState.clearAll()
            }
        }
    }

    Text {
        visible: NotificationState.count === 0
        font.family: Style.textFont
        font.pixelSize: 12
        color: Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.55)
        text: "No notifications yet this session."
    }

    Column {
        width: parent.width
        spacing: 6

        Repeater {
            model: NotificationState.log

            Rectangle {
                id: card
                required property var modelData
                width: root.width
                height: cardBody.implicitHeight + 14
                radius: 6
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.55)
                border.width: 1
                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)

                Column {
                    id: cardBody
                    x: 8
                    y: 7
                    width: parent.width - 16
                    spacing: 2

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - 14
                            font.family: Style.textFont
                            font.pixelSize: 10
                            color: Colors.primary
                            text: (card.modelData.appName || "").toUpperCase()
                        }
                        Text {
                            font.family: Style.textFont
                            font.pixelSize: 10
                            opacity: 0.55
                            color: Colors.tertiary
                            text: card.modelData.timeText || ""
                        }
                    }
                    Text {
                        width: parent.width
                        visible: !!card.modelData.summary
                        font.family: Style.textFont
                        font.pixelSize: 12
                        color: Colors.backgroundText
                        text: card.modelData.summary || ""
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        visible: !!card.modelData.body
                        font.family: Style.textFont
                        font.pixelSize: 11
                        opacity: 0.85
                        color: Colors.backgroundText
                        text: card.modelData.body || ""
                        wrapMode: Text.WordWrap
                    }
                }

                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    font.family: Style.iconFont
                    font.pixelSize: 11
                    color: Colors.outline
                    text: "\u{F0156}"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: NotificationState.dismiss(card.modelData.ts)
                    }
                }
            }
        }
    }
}
