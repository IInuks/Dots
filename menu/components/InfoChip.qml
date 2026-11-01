import QtQuick
import ".."

// Small "label: value" chip under the preview (Deckkraft, Radius, ...).
Rectangle {
    id: chip
    property string icon: ""
    property string text: ""
    property color tint: Theme.textDim

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24
    radius: height / 2
    color: Theme.panelAlt
    border.width: Theme.borderWidth
    border.color: Theme.border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            visible: chip.icon.length > 0
            text: chip.icon
            size: Theme.fontXs
            color: chip.tint
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: chip.text
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
