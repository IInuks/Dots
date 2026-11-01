import QtQuick
import ".."

// Fixed 1-5 range (spec: "immer 1 bis 5 anzeigen"), unlike
// klasic/Tags.qml's full 9-tag display. Active tag gets a lighter
// background + its own thin border; occupied-but-inactive tags show a
// small dot; empty tags show just their number. Click switches, wheel
// scrolls to the adjacent tag.
Item {
    id: root
    required property string outputName

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function _activeIndex() {
        const active = MangoIpc.activeTagsFor(root.outputName);
        return active.length > 0 ? active[0] : 1;
    }

    Row {
        id: row
        spacing: 4

        Repeater {
            model: 5
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
                radius: 5
                color: slot.active ? Theme.activeHighlight : "transparent"
                border.width: slot.active ? 1 : 0
                border.color: slot.urgent ? Theme.urgent : Theme.activeBorder
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    visible: !slot.occupied
                    text: slot.tagIndex
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: slot.active ? Theme.text : Theme.textMuted
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: slot.occupied
                    width: 5
                    height: 5
                    radius: 2.5
                    color: slot.urgent ? Theme.urgent : (slot.active ? Theme.text : Theme.textMuted)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MangoIpc.viewTag(root.outputName, slot.tagIndex)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: row
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const cur = root._activeIndex();
            const next = wheel.angleDelta.y > 0 ? Math.max(1, cur - 1) : Math.min(5, cur + 1);
            MangoIpc.viewTag(root.outputName, next);
        }
    }
}
