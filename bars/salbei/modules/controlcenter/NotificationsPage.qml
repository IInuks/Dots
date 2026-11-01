import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.tileGap
        ListRow {
            Layout.preferredWidth: 190
            icon: Ui.dnd ? "notifications_off" : "do_not_disturb_on"
            label: "Do not disturb"
            selected: Ui.dnd
            onClicked: Ui.dnd = !Ui.dnd
        }
        Item { Layout.fillWidth: true }
        ListRow {
            Layout.preferredWidth: 120
            icon: "delete"
            label: "Clear all"
            interactive: Notifs.history.length > 0
            opacity: interactive ? 1 : 0.45
            onClicked: Notifs.clear()
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.tileGap
        model: ScriptModel { values: Notifs.history; objectProp: "key" }
        boundsBehavior: Flickable.StopAtBounds

        // dismissed cards swipe out to the right (cascading on "Clear all"), the rest closes the gap
        remove: Transition {
            SequentialAnimation {
                PauseAnimation { duration: Math.max(0, Math.min(ViewTransition.index, 8)) * 35 }
                ParallelAnimation {
                    NumberAnimation { property: "x"; to: list.width * 0.7; duration: 280; easing.type: Easing.InCubic }
                    NumberAnimation { property: "opacity"; to: 0; duration: 260 }
                }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "y"; duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 1.1 }
        }
        ScrollBar.vertical: ScrollBar { width: 3; contentItem: Rectangle { implicitWidth: 3; radius: 1.5; color: Theme.textFaint } }

        delegate: Tile {
            id: card
            required property var modelData
            required property int index
            order: index
            width: list.width
            height: content.implicitHeight + 24

            RowLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                AppIcon {
                    Layout.alignment: Qt.AlignTop
                    size: 32
                    icon: card.modelData.image || card.modelData.appIcon
                    fallbackText: card.modelData.appName
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Txt { text: card.modelData.summary; font.weight: Font.Bold; Layout.fillWidth: true }
                        Txt { text: Qt.formatTime(card.modelData.time, "hh:mm"); color: Theme.textFaint; font.pixelSize: Theme.fontTiny }
                    }
                    Txt { Layout.fillWidth: true; text: card.modelData.appName; color: Theme.textFaint; font.pixelSize: Theme.fontTiny }
                    Txt {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: card.modelData.body
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Normal
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                    }
                }
                IconButton {
                    Layout.alignment: Qt.AlignTop
                    icon: "close"
                    filled: false
                    implicitWidth: 22
                    implicitHeight: 22
                    iconSize: 14
                    onClicked: Notifs.remove(card.modelData.key)
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No notifications"
            color: Theme.textDim
        }
    }
}
