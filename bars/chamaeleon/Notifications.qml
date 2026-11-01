import QtQuick

// The notification flyout: log of received notifications, newest first,
// each dismissible; "Clear all" wipes the log. Opening the panel marks
// everything seen (clears the bar badge). Same PopupFrame shell as
// ControlCenter.qml/Launcher.qml.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.notificationsWidth
    panelHeight: Metrics.notificationsHeight

    onShownChanged: if (shown) NotifyHub.markSeen()

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            width: parent.width
            Text {
                text: "Notifications"
                color: Theme.text
                font.family: Metrics.fontFamily
                font.pixelSize: 13
                font.bold: true
                width: parent.width - 70
            }
            Text {
                visible: NotifyHub.log.length > 0
                text: "Clear all"
                color: Theme.textFaint
                font.family: Metrics.fontFamily
                font.pixelSize: 10
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotifyHub.clearAll()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.textFaint, 0.2) }

        Flickable {
            width: parent.width
            height: parent.height - 40
            clip: true
            contentHeight: col.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 10

                Text {
                    visible: NotifyHub.log.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 40
                    text: "No notifications"
                    color: Theme.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 12
                    font.italic: true
                }

                Repeater {
                    model: NotifyHub.log

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        width: col.width
                        height: body.implicitHeight + 22
                        radius: Theme.rSmall
                        color: Theme.panelRaised

                        opacity: 0
                        Component.onCompleted: entrance.start()
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation { duration: Math.min(card.index, 8) * 35 }
                            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 200 }
                        }

                        Column {
                            id: body
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 11
                            spacing: 3

                            Row {
                                width: parent.width
                                Text {
                                    text: (card.modelData.app || "") + " · " + (card.modelData.stamp || "")
                                    color: Theme.textFaint
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 10
                                    width: parent.width - 16
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "✕"
                                    color: Theme.textFaint
                                    font.pixelSize: 10
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotifyHub.dismiss(card.modelData.id)
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                visible: !!card.modelData.title
                                text: card.modelData.title || ""
                                color: Theme.text
                                font.family: Metrics.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                width: parent.width
                                visible: !!card.modelData.body
                                text: card.modelData.body || ""
                                color: Theme.textFaint
                                font.family: Metrics.fontFamily
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
