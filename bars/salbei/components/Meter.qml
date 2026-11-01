import QtQuick
import QtQuick.Layouts
import "../"

// Percentage tile: icon + label, rolling number, bar, detail line.
Tile {
    id: m
    property string icon
    property string label
    property real value
    property string detail
    Layout.fillWidth: true
    Layout.preferredHeight: 118

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6
        RowLayout {
            Icon { name: m.icon; size: Theme.iconItem; color: Theme.accent }
            Txt { text: m.label; font.weight: Font.DemiBold }
        }
        RollingText { text: Math.round(m.value * 100) + "%"; pixelSize: 22; weight: Font.Bold; duration: 300 }
        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.track
            Rectangle {
                // meters fill up on open and glide between readings
                property real grow: 0
                NumberAnimation on grow { from: 0; to: 1; duration: 900; easing.type: Theme.easingEmph }
                property real v: Math.min(1, m.value)
                Behavior on v { NumberAnimation { duration: 700; easing.type: Theme.easing } }
                width: parent.width * v * grow
                height: parent.height; radius: 3
                color: m.value > 0.85 ? Theme.danger : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.animSlow } }
            }
        }
        Txt { Layout.fillWidth: true; text: m.detail; color: Theme.textDim; font.pixelSize: Theme.fontTiny }
    }
}
