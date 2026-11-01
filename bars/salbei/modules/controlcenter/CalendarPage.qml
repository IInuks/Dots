import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../../components"

RowLayout {
    spacing: Theme.tileGap

    SystemClock { id: clock; precision: SystemClock.Hours }

    Tile {
        order: 1
        Layout.fillHeight: true
        Layout.preferredWidth: 340
        MonthGrid {
            anchors.centerIn: parent
            width: 300
            today: clock.date
            cell: 36
            fontSize: Theme.fontItem
        }
    }
    Tile {
        order: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 4
            Txt { text: Qt.locale("en_US").toString(clock.date, "dddd d MMMM"); font.weight: Font.Bold; font.pixelSize: Theme.fontHeading }
            Txt { text: "No events."; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
            Item { Layout.fillHeight: true }
        }
    }
}
