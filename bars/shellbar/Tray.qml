import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

// Background-app icons (StatusNotifierItem tray, e.g. Discord). Left click
// activates, right click opens the item's native context menu anchored to
// the bar window.
Item {
    id: root

    required property var hostWindow
    readonly property bool vertical: Settings.vertical

    implicitWidth: vertical ? Settings.barThickness : row.implicitWidth
    implicitHeight: vertical ? row.implicitHeight : Settings.barThickness

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: iconDelegate
                required property var modelData
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

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
}
