import QtQuick

// 9 mango tags as small rounded squares. Mango allows several tags to be
// active at once on one monitor (MangoIpc.activeTagsFor returns an array),
// so "active" is membership, not equality with a single index.
Row {
    id: root
    required property string outputName
    spacing: 4

    Repeater {
        model: 9
        delegate: Rectangle {
            id: slot
            required property int index
            readonly property int tagIndex: index + 1
            readonly property var tagData: MangoIpc.tagsFor(root.outputName).find(t => t.index === slot.tagIndex)
            readonly property bool occupied: tagData ? tagData.client_count > 0 : false
            readonly property bool urgent: tagData ? tagData.is_urgent : false
            readonly property bool active: MangoIpc.activeTagsFor(root.outputName).indexOf(slot.tagIndex) !== -1

            width: 18
            height: 18
            radius: Theme.radiusSmall
            color: active ? Theme.accent : (occupied ? Qt.alpha(Theme.text, 0.12) : "transparent")
            border.width: 1
            border.color: urgent ? Theme.urgent : (active ? Theme.accent : Theme.border)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: slot.tagIndex
                font.pixelSize: 10
                font.bold: slot.active
                color: slot.urgent ? Theme.urgent : (slot.active ? Theme.background : (slot.occupied ? Theme.text : Theme.textMuted))
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MangoIpc.viewTag(root.outputName, slot.tagIndex)
            }
        }
    }
}
