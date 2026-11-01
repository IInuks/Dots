import QtQuick
import "../"

// Row of vertical bars driven by CavaService.levels. Bare Item delegates
// inside the Row (not the Rectangles directly) since QtQuick positioners
// reject anchors on their immediate children -- the Rectangle inside each
// Item anchors to *that* Item's bottom instead (same trick already used
// for chamfer-safe segments elsewhere in this repo).
Item {
    id: root
    implicitHeight: 32

    Row {
        anchors.fill: parent
        spacing: 3

        Repeater {
            model: CavaService.barCount

            Item {
                id: slot
                required property int index
                width: (root.width - (CavaService.barCount - 1) * 3) / CavaService.barCount
                height: root.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, (CavaService.levels.length > slot.index ? CavaService.levels[slot.index] : 0) * parent.height)
                    radius: width / 2
                    color: Theme.primary

                    Behavior on height {
                        NumberAnimation { duration: 90; easing.type: Theme.easeOut }
                    }
                }
            }
        }
    }
}
