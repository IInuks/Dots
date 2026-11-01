import QtQuick
import "../.."
import "../../widgets/segment"

// The 9 mango tags for one monitor, as small LCD slots with a SevenSegment
// digit (1-9) each -- never Text, same "no font" rule as the clock. Mango
// allows several tags active at once per monitor, so "active" is set
// membership (MangoIpc.activeTagsFor), not equality with one index.
Row {
    id: root

    required property string outputName
    spacing: 3

    readonly property real digitHeight: Theme.density === "compact" ? 12 : 14
    readonly property real slotSize: digitHeight + 10

    Repeater {
        model: 9

        Rectangle {
            id: slot
            required property int index
            readonly property int tagIndex: index + 1
            readonly property var tagData: MangoIpc.tagsFor(root.outputName).find(t => t.index === slot.tagIndex)
            readonly property bool occupied: tagData ? tagData.client_count > 0 : false
            readonly property bool urgent: tagData ? tagData.is_urgent : false
            readonly property bool active: MangoIpc.activeTagsFor(root.outputName).indexOf(slot.tagIndex) !== -1

            width: root.slotSize
            height: root.slotSize
            radius: Theme.radius * 0.6
            color: active ? Theme.accent : "transparent"
            border.width: 1
            border.color: active ? Theme.accent : Theme.bevelDark
            Behavior on color {
                ColorAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeOut
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeOut
                }
            }

            SevenSegment {
                anchors.centerIn: parent
                char: String(slot.tagIndex)
                digitHeight: root.digitHeight
                // Theme.segmentOn is derived from the same accent hue as
                // the active tile's background (see Theme.qml), so it all
                // but disappears on top of it -- accentInk is the role
                // built for exactly this "ink on an accent surface" case.
                onColor: slot.active ? Theme.accentInk : Theme.segmentOn
                opacity: slot.occupied || slot.active ? 1 : 0.4
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durBase
                    }
                }
            }

            // Separate overlay for the urgent pulse rather than animating
            // `color` directly -- `color` already carries a declarative
            // binding above, and a value-source animation on the same
            // property would permanently replace that binding once the
            // animation stops (same family of issue as the
            // Behavior+animator freeze noted in project memory).
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.critical
                opacity: 0
                visible: slot.urgent

                SequentialAnimation on opacity {
                    running: slot.urgent
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.85
                        duration: Theme.durSlow * 2
                        easing.type: Theme.easeInOut
                    }
                    NumberAnimation {
                        to: 0
                        duration: Theme.durSlow * 2
                        easing.type: Theme.easeInOut
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MangoIpc.viewTag(root.outputName, slot.tagIndex)
            }
        }
    }
}
