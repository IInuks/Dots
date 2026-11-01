import QtQuick
import Quickshell
import ".."

// Workspace tags as an equalizer-style tick row instead of numbered pills:
// empty tags sit low and dim, occupied tags rise and brighten, the active
// tag rises tallest in the accent color. Click jumps to a tag, scroll
// steps through them.
Item {
    id: root
    required property ShellScreen screen

    readonly property var tags: Session.tagsOn(root.screen.name)
    readonly property int activeIndex: Session.activeTagOn(root.screen.name)

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.barHeight - 16

    Row {
        id: row
        anchors.bottom: parent.bottom
        spacing: 5

        Repeater {
            model: Metrics.tagCount
            delegate: Item {
                id: slot
                required property int index
                readonly property int tagNumber: slot.index + 1
                readonly property var tagData: root.tags.find(t => t.index === slot.tagNumber)
                readonly property bool occupied: slot.tagData ? slot.tagData.client_count > 0 : false
                readonly property bool active: slot.tagNumber === root.activeIndex

                readonly property real tickHeight: slot.active ? 22 : (slot.occupied ? 13 : 7)

                width: 6
                height: root.implicitHeight

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 6
                    radius: 3
                    height: slot.tickHeight
                    color: slot.active ? Chroma.accent : (slot.occupied ? Chroma.textFaint : Qt.alpha(Chroma.textFaint, 0.35))
                    Behavior on height { SpringAnimation { spring: 3.4; damping: 0.42 } }
                    Behavior on color { ColorAnimation { duration: Chroma.tMed } }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Session.goToTag(root.screen.name, slot.tagNumber)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const dir = wheel.angleDelta.y > 0 ? -1 : 1;
            const next = Math.min(Math.max(root.activeIndex + dir, 1), Metrics.tagCount);
            Session.goToTag(root.screen.name, next);
        }
    }
}
