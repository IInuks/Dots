import QtQuick
import Quickshell.Services.SystemTray
import "../"

// Tray-pill content: one row per SNI item. Real app icon (QIcon/pixmap via
// modelData.icon), not a Material glyph -- can't redraw an app's own tray
// icon as a symbol. Left-click activates, right-click opens the item's own
// context menu via modelData.display(), anchored to the bar's PanelWindow
// (needs a real Quickshell window, not just any Item -- passed down as
// hostWindow from Bar.qml). Same SystemTray.items + display() approach
// already proven in bars/claude/Bar/TrayRow.qml and bars/fisheye/bar/
// modules/TrayModule.qml, restyled into this bar's scrollable-list
// convention (ClockPanel/SystemPanel) instead of an always-visible row.
Flickable {
    id: root

    required property var hostWindow

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: layout
        width: root.width
        spacing: 8
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        Text {
            text: "Tray"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.uiFontFamily
        }

        Repeater {
            model: SystemTray.items

            Row {
                id: entryRow
                required property var modelData
                width: layout.width - 28
                height: 28
                spacing: 8

                Image {
                    id: trayIcon
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    source: entryRow.modelData.icon
                    asynchronous: true
                    smooth: true
                }

                Text {
                    width: parent.width - trayIcon.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: entryRow.modelData.tooltipTitle || entryRow.modelData.title || entryRow.modelData.id || "?"
                    color: Theme.surfaceInk
                    font.pixelSize: 11
                    font.family: Theme.uiFontFamily
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            entryRow.modelData.activate();
                        } else if (entryRow.modelData.hasMenu) {
                            const p = entryRow.mapToItem(null, mouse.x, mouse.y);
                            entryRow.modelData.display(root.hostWindow, p.x, p.y);
                        }
                    }
                }
            }
        }

        Text {
            visible: SystemTray.items.values.length === 0
            text: "Keine Tray-Icons"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }
    }
}
