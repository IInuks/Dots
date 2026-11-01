import QtQuick

// Small icon+label+value tile for secondary system stats (temps, disk,
// uptime, network).
Rectangle {
    id: tile

    property string icon: "gear"
    property string label: ""
    property string value: "—"
    property color accent: Theme.accent

    implicitHeight: 58
    radius: Theme.radiusMed
    color: Theme.surfaceAlt

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 30; height: 30; radius: Theme.radiusSmall
            color: Qt.alpha(tile.accent, 0.18)
            anchors.verticalCenter: parent.verticalCenter
            Icon { anchors.centerIn: parent; name: tile.icon; size: 15; tint: tile.accent }
        }

        Column {
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter
            Text { text: tile.label; color: Theme.textDim; font.pixelSize: 10 }
            Text { text: tile.value; color: Theme.text; font.pixelSize: 13; font.bold: true }
        }
    }
}
