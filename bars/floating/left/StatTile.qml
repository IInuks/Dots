import QtQuick
import QtQuick.Layouts
import ".."

// Small label+value tile, ported from shellbar/StatTile.qml, monochrome.
Rectangle {
    id: tile

    property string label: ""
    property string value: ""

    Layout.fillWidth: true
    radius: 8
    color: Qt.alpha(Theme.textMuted, 0.08)
    implicitHeight: tileCol.implicitHeight + 14

    ColumnLayout {
        id: tileCol
        anchors.fill: parent
        anchors.margins: 7
        spacing: 2
        Text { text: tile.label; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 9 }
        Text { text: tile.value; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
    }
}
