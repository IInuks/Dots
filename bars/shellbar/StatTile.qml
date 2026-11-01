import QtQuick
import QtQuick.Layouts

// Small label+value tile used for temps/disk/uptime in SettingsMenu's
// Monitor tab.
Rectangle {
    id: tile

    property string label: ""
    property string value: ""

    Layout.fillWidth: true
    radius: 10
    color: Qt.alpha(Theme.mutedText, 0.07)
    implicitHeight: tileCol.implicitHeight + 16

    ColumnLayout {
        id: tileCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2
        Text { text: tile.label; color: Theme.mutedText; font.pixelSize: 10 }
        Text { text: tile.value; color: Theme.foreground; font.pixelSize: 13; font.bold: true }
    }
}
