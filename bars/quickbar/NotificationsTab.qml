import QtQuick

Item {
    id: root

    Text {
        visible: NotificationState.items.length === 0
        anchors.centerIn: parent
        text: "Keine neuen Nachrichten"
        color: Theme.textDim
        font.pixelSize: 13
        font.italic: true
    }

    Column {
        id: header
        visible: NotificationState.items.length > 0
        width: parent.width
        spacing: 0

        Row {
            width: parent.width
            Item { width: parent.width - clearBtn.implicitWidth; height: 1 }
            Text {
                id: clearBtn
                text: "Alle löschen"
                color: Theme.accent
                font.pixelSize: 12
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: NotificationState.clearAll() }
            }
        }
    }

    ListView {
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        model: NotificationState.items

        add: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Theme.animMed }
        }
        displaced: Transition {
            NumberAnimation { properties: "y"; duration: Theme.animMed; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: card
            required property var modelData
            width: ListView.view.width
            height: 52
            radius: Theme.radiusMed
            color: Theme.surfaceAlt

            SequentialAnimation on x {
                id: removeAnim
                running: false
                NumberAnimation { to: card.width; duration: Theme.animFast; easing.type: Easing.InCubic }
                ScriptAction { script: NotificationState.dismiss(card.modelData.id) }
            }

            Column {
                anchors.left: parent.left
                anchors.right: closeIcon.left
                anchors.margins: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: (card.modelData.appName || "") + " · " + card.modelData.summary
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: card.modelData.body || ""
                    color: Theme.textDim
                    font.pixelSize: 11
                }
            }

            Icon {
                id: closeIcon
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                name: "close"; size: 11; tint: Theme.textDim
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: removeAnim.running = true }
            }
        }
    }
}
