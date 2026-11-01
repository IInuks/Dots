import QtQuick
import "../"
import "../Bar"

// Notifications-pill content: DND switch, "Alle löschen", then the log
// newest-first -- same scrollable Flickable+Column convention as
// SystemPanel/TrayPanel/ClockPanel. Opening the panel marks the log seen
// (clears the pill's unread badge, wired in Bar.qml).
Flickable {
    id: root

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    Component.onCompleted: NotificationState.markSeen()

    Column {
        id: layout
        width: root.width
        spacing: 10
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        Row {
            width: parent.width - 28
            spacing: 6

            Text {
                text: "Notifications"
                color: Theme.surfaceInk
                font.pixelSize: 12
                font.bold: true
                font.family: Theme.uiFontFamily
                width: parent.width - dndToggle.width - dndLabel.width - 12
            }
            Text {
                id: dndLabel
                text: "Nicht stören"
                color: Theme.outline
                font.pixelSize: 10
                font.family: Theme.uiFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
            Toggle {
                id: dndToggle
                checked: Config.dnd
                onToggled: v => Config.setDnd(v)
            }
        }

        Text {
            visible: NotificationState.log.length > 0
            text: "Alle löschen"
            color: Theme.outline
            font.pixelSize: 10
            font.family: Theme.uiFontFamily
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationState.clearAll()
            }
        }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        Text {
            visible: NotificationState.log.length === 0
            width: parent.width - 28
            horizontalAlignment: Text.AlignHCenter
            topPadding: 20
            text: "Keine Benachrichtigungen"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
            font.italic: true
        }

        Repeater {
            model: NotificationState.log

            Column {
                id: card
                required property var modelData
                width: layout.width - 28
                spacing: 3

                Row {
                    width: parent.width
                    Text {
                        width: parent.width - 16
                        text: (card.modelData.app || "") + " · " + (card.modelData.stamp || "")
                        color: Theme.outline
                        font.pixelSize: 10
                        font.family: Theme.uiFontFamily
                        elide: Text.ElideRight
                    }
                    Icon {
                        glyph: "close"
                        fallback: "×"
                        font.pixelSize: 12
                        color: Theme.outline
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: NotificationState.dismiss(card.modelData.id)
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: !!card.modelData.title
                    text: card.modelData.title || ""
                    color: Theme.surfaceInk
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.uiFontFamily
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    visible: !!card.modelData.body
                    text: card.modelData.body || ""
                    color: Theme.surfaceVariantInk
                    font.pixelSize: 11
                    font.family: Theme.uiFontFamily
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    visible: card.modelData.actions && card.modelData.actions.length > 0
                    spacing: 6
                    topPadding: 2

                    Repeater {
                        model: card.modelData.actions || []
                        Rectangle {
                            id: actionBtn
                            required property var modelData
                            radius: 6
                            color: actionArea.containsMouse ? Theme.surfaceVariant : Theme.surfaceContainer
                            border.width: 1
                            border.color: Theme.outlineVariant
                            implicitWidth: actionLabel.implicitWidth + 14
                            implicitHeight: 22

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: actionBtn.modelData.text || ""
                                color: Theme.surfaceInk
                                font.pixelSize: 10
                                font.family: Theme.uiFontFamily
                            }
                            MouseArea {
                                id: actionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: actionBtn.modelData.invoke()
                            }
                        }
                    }
                }

                Item { width: 1; height: 4 }
                Rectangle { width: parent.width; height: 1; color: Theme.outlineVariant }
            }
        }
    }
}
