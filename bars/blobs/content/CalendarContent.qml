import QtQuick
import ".."

// Wochentage Mo-So, aktueller Tag hervorgehoben (Auftrag Abschnitt 5b).
Item {
    id: root

    required property date today

    readonly property var _labels: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    // getDay(): 0=So..6=Sa -> Index in Mo..So-Reihenfolge verschieben.
    readonly property int _todayIndex: (root.today.getDay() + 6) % 7

    Row {
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root._labels

            Rectangle {
                id: cell
                required property string modelData
                required property int index

                width: 32
                height: 32
                radius: 8
                color: cell.index === root._todayIndex ? Theme.primary : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: cell.modelData
                    font.pixelSize: 12
                    color: cell.index === root._todayIndex ? Theme.primaryInk : Theme.surfaceInk
                }
            }
        }
    }
}
