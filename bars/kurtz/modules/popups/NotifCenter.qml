import QtQuick
import "../../"
import "../../components"
import "../../services"

// Notification center: header (count, DND, clear), scrollable history.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    Component.onCompleted: Notifs.markSeen()

    Column {
        id: col
        width: parent.width
        spacing: Theme.s3

        Item {
            width: parent.width
            height: 40
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.s3
                Orb {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30
                    color: Theme.purple
                    glowing: Notifs.history.length > 0
                    KLabel {
                        anchors.centerIn: parent
                        text: Notifs.history.length
                        font.weight: Font.Bold
                        color: Theme.bgTop
                    }
                }
                KLabel { anchors.verticalCenter: parent.verticalCenter; role: "big"; text: "Mitteilungen" }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.s2
                KLabel { anchors.verticalCenter: parent.verticalCenter; role: "muted"; text: "Nicht stören" }
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Config.s.dnd
                    color: Theme.purple
                    onToggled: v => Config.set("dnd", v)
                }
            }
        }

        // empty state
        Column {
            visible: Notifs.history.length === 0
            width: parent.width
            spacing: Theme.s2
            Item { width: 1; height: Theme.s3 }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 90; height: 70
                Orb { x: 18; y: 8; width: 54; height: 54; color: Theme.purple; ring: true; glowing: true }
                Orb { x: 0; y: 44; width: 14; height: 14; color: Theme.cyan }
                Orb { x: 76; y: 4; width: 10; height: 10; color: Theme.yellow }
            }
            KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "title"; text: "Alles ruhig im Orbit" }
            KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "muted"; text: "Keine neuen Mitteilungen" }
            Item { width: 1; height: Theme.s3 }
        }

        ListView {
            id: list
            visible: Notifs.history.length > 0
            width: parent.width
            height: Math.min(contentHeight, 460)
            clip: true
            spacing: Theme.s2
            model: Notifs.history
            boundsBehavior: Flickable.StopAtBounds

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.tMed }
                NumberAnimation { property: "x"; from: 30; duration: Theme.tPop; easing.type: Theme.easePop }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.tFast }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: Theme.tMed; easing.type: Theme.easeOut }
            }

            delegate: NotifCard {
                required property var modelData
                width: list.width
                entry: modelData
            }
        }

        Chip {
            visible: Notifs.history.length > 0
            anchors.right: parent.right
            text: "Alle löschen"
            glyph: Glyphs.trash
            tint: Theme.crit
            onClicked: Notifs.clearAll()
        }
    }
}
