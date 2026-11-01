import QtQuick
import Quickshell.Services.SystemTray
import "../"

// SNI tray icons, real app icons via modelData.icon (same source
// bars/lucid/Panels/TrayPanel.qml and bars/claude/Bar/TrayRow.qml already
// proved). Left-click activates; no right-click context menu yet (needs a
// hostWindow to anchor a popup menu against -- Stage 2, see README
// "Bekannte Lücken").
Row {
    id: root
    spacing: 6
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items
        delegate: Image {
            id: trayIcon
            required property var modelData
            source: modelData.icon
            width: 16
            height: 16
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: trayIcon.modelData.activate()
            }
        }
    }
}
