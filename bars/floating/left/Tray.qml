import QtQuick
import Quickshell.Services.SystemTray

// Background-app tray icons, same approach as shellbar/Tray.qml trimmed to
// this bar's always-horizontal layout. Left click activates, right click
// opens the item's native context menu anchored to the island window.
Row {
    id: root
    required property var hostWindow
    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: iconDelegate
            required property var modelData
            width: 16
            height: 16

            Image {
                anchors.fill: parent
                source: iconDelegate.modelData.icon
                asynchronous: true
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
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
