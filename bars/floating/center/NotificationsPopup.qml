import QtQuick
import QtQuick.Layouts
import ".."

// Bell click target (spec 4 "Benachrichtigungsmenü"): list with app
// icon/name/title/text/time, per-item close, action buttons when present,
// "Alle löschen", and a "Nicht disturb" switch that suppresses toasts (see
// NotificationState.dndEnabled) while the unread counter keeps counting.
// Opening this popup marks everything read (spec: "Öffnen des Menüs setzt
// den Zähler auf 0").
PopupBase {
    id: popup
    popupWidth: 300
    popupHeight: Math.min(col.implicitHeight + 20, 420)

    Component.onCompleted: NotificationState.markRead()

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: popup.popupWidth - 20
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Nicht stören"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                Toggle {
                    checked: NotificationState.dndEnabled
                    onToggled: v => NotificationState.setDnd(v)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: NotificationState.items.length > 0
                Item { Layout.fillWidth: true }
                Text {
                    text: "Alle löschen"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationState.clearAll()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

            Text {
                visible: NotificationState.items.length === 0
                text: "Keine Benachrichtigungen"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
            }

            Repeater {
                model: NotificationState.items

                delegate: ColumnLayout {
                    id: item
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Image {
                            visible: !!item.modelData.appIcon
                            source: item.modelData.appIcon || ""
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            asynchronous: true
                        }
                        Text {
                            text: item.modelData.appName || ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            Layout.fillWidth: true
                        }
                        Text {
                            text: item.modelData.time || ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        Icon {
                            name: "close"
                            size: 9
                            tint: Theme.textMuted
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationState.dismiss(item.modelData.id)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: !!item.modelData.summary
                        text: item.modelData.summary || ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!item.modelData.body
                        text: item.modelData.body || ""
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: item.modelData.actions && item.modelData.actions.length > 0
                        spacing: 6

                        Repeater {
                            model: item.modelData.actions || []
                            delegate: Rectangle {
                                id: actionBtn
                                required property var modelData
                                radius: 6
                                color: actionArea.containsMouse ? Qt.alpha(Theme.textMuted, 0.18) : Qt.alpha(Theme.textMuted, 0.08)
                                implicitWidth: actionLabel.implicitWidth + 14
                                implicitHeight: 20

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.text || ""
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
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

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.12); Layout.topMargin: 4 }
                }
            }
        }
    }
}
