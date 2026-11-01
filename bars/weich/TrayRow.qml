import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// Content-only (lives inside a Pane in RightCluster.qml): one icon per
// registered status-notifier item, left-click activates, right-click opens
// its own menu via QsMenuAnchor.
Row {
    id: root
    spacing: 8
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        delegate: Item {
            id: trayItem
            required property var modelData
            width: 18
            height: 18

            IconImage {
                id: icon
                anchors.fill: parent
                source: trayItem.modelData.icon
            }

            QsMenuAnchor {
                id: menuAnchor
                anchor.item: trayItem
                menu: trayItem.modelData.menu
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (trayItem.modelData.hasMenu) menuAnchor.open();
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else {
                        trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
