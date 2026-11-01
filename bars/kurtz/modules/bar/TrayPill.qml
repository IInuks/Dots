import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../"
import "../../components"

// System tray: each app icon sits in its own little circular badge.
// Left = activate, right = the app's own menu.
Pill {
    id: root
    property var hostWindow
    readonly property int count: SystemTray.items.values.length
    interactive: false
    padding: Theme.s1 + 2
    spacing: Theme.s1

    Repeater {
        model: SystemTray.items

        Item {
            id: item
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.pillHeight - 8
            height: width
            scale: ma.containsMouse ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: 2 } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: ma.containsMouse ? Theme.surfaceHover : Theme.surfaceRaised
                Behavior on color { ColorAnimation { duration: Theme.tFast } }
            }
            Image {
                anchors.centerIn: parent
                width: parent.width * 0.58
                height: width
                source: item.modelData.icon
                sourceSize.width: 32
                sourceSize.height: 32
                asynchronous: true
                smooth: true
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    if (m.button === Qt.LeftButton && !item.modelData.onlyMenu) {
                        item.modelData.activate();
                    } else if (m.button === Qt.MiddleButton) {
                        item.modelData.secondaryActivate();
                    } else if (item.modelData.hasMenu) {
                        const p = item.mapToItem(null, m.x, m.y);
                        item.modelData.display(root.hostWindow, p.x, p.y);
                    }
                }
            }
        }
    }
}
