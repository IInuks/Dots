import QtQuick
import Quickshell.Services.SystemTray
import "../.."

// Same approach as the other quickdots bars' Tray.qml: SystemTray.items are
// real icon images (asynchronous QIcon/pixmap data), not glyphs, so this is
// the one place in fisheye that legitimately shows non-segment, non-Theme
// graphics -- an app's own tray icon can't be redrawn as an LCD digit.
Row {
    id: root

    required property var hostWindow
    spacing: 8

    Repeater {
        model: SystemTray.items

        Item {
            id: iconDelegate
            required property var modelData
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            scale: hoverArea.containsMouse ? 1.2 : 1
            Behavior on scale {
                SpringAnimation {
                    spring: 3
                    damping: 0.3
                }
            }

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
