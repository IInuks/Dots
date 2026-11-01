import QtQuick
import Quickshell.Services.SystemTray

Row {
    id: root
    required property var hostWindow
    spacing: 10

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: iconDelegate
            required property var modelData
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            scale: hoverArea.containsMouse ? 1.25 : 1
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }

            Image {
                anchors.fill: parent
                source: iconDelegate.modelData.icon
                asynchronous: true
                smooth: true
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        iconDelegate.modelData.activate();
                    } else if (mouse.button === Qt.RightButton && iconDelegate.modelData.hasMenu) {
                        const p = iconDelegate.mapToItem(null, mouse.x, mouse.y);
                        iconDelegate.modelData.display(root.hostWindow, p.x, p.y);
                    }
                }
            }
        }
    }
}
