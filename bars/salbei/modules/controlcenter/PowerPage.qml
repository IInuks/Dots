import QtQuick
import QtQuick.Layouts
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    Txt {
        text: "Click twice to confirm."
        color: Theme.textDim
        font.pixelSize: Theme.fontSmall
    }
    PowerActions {
        Layout.fillWidth: true
        tileHeight: 110
        onDone: Ui.controlCenterOpen = false
    }
    Tile {
        order: 4
        visible: Battery.available
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            Icon { name: Battery.icon; size: 22; color: Battery.charging ? Theme.accent : Battery.low ? Theme.danger : Theme.text }
            Txt { text: "Battery " + Math.round(Battery.percent * 100) + "%" + (Battery.charging ? " · charging" : ""); Layout.fillWidth: true }
        }
    }
    Item { Layout.fillHeight: true }
}
