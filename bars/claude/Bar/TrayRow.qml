import QtQuick
import Quickshell.Services.SystemTray
import ".."

Row {
    id: root
    required property var hostWindow
    spacing: 9

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property var modelData
            width: 15
            height: 15
            anchors.verticalCenter: parent.verticalCenter
            scale: hoverArea.containsMouse ? 1.2 : 1
            Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.3 } }

            Image {
                anchors.fill: parent
                source: entry.modelData.icon
                asynchronous: true
                smooth: true
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        entry.modelData.activate();
                    } else if (entry.modelData.hasMenu) {
                        const p = entry.mapToItem(null, mouse.x, mouse.y);
                        entry.modelData.display(root.hostWindow, p.x, p.y);
                    }
                }
            }
        }
    }
}
