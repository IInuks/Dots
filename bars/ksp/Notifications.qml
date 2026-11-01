import QtQuick

// Notification flyout styled as a comms/mission log: newest entry first,
// each dismissible, "CLEAR LOG" wipes it. Opening marks everything seen
// (clears the bar badge). Same PopupFrame shell as Launcher/ControlCenter.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.notificationsWidth
    panelHeight: Metrics.notificationsHeight
    title: "Mission Log"

    onShownChanged: if (shown) NotifyHub.markSeen()

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            width: parent.width
            Text {
                text: NotifyHub.log.length + " ENTRIES"
                color: Theme.textFaint
                font.family: Metrics.fontMono
                font.pixelSize: 10
                font.letterSpacing: 1
                width: parent.width - 70
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: NotifyHub.log.length > 0
                text: "CLEAR LOG"
                color: Theme.accent
                font.family: Metrics.fontMono
                font.pixelSize: 10
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotifyHub.clearAll()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.accent, 0.25) }

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
                    text: "NO SIGNAL"
                    color: Theme.textFaint
                    font.family: Metrics.fontMono
                    font.pixelSize: 12
                    font.letterSpacing: 1
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
                        border.width: 1
                        border.color: Qt.alpha(Theme.accent, 0.15)

                        opacity: 0
                        x: -12
                        Component.onCompleted: entrance.start()
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation { duration: Math.min(card.index, 8) * 35 }
                            ParallelAnimation {
                                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 200 }
                                NumberAnimation { target: card; property: "x"; to: 0; duration: 220; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            color: Theme.accent
                        }

                        Column {
                            id: body
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 11
                            anchors.leftMargin: 15
                            spacing: 3

                            Row {
                                width: parent.width
                                Text {
                                    text: (card.modelData.app || "UNKNOWN").toUpperCase() + " · " + (card.modelData.stamp || "")
                                    color: Theme.textFaint
                                    font.family: Metrics.fontMono
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.5
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
