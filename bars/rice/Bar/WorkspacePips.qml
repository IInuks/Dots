import QtQuick
import "../"

// Workspace indicator as segmented ticks (thin vertical bars), not
// dots/numbers/pills -- deliberately distinct from every sibling bar's
// workspace rendering (bars/simple, bars/lucid, bars/floating all use
// pills; bars/kompass uses a gauge needle). Height encodes state: active
// tag tallest + accent-filled, occupied medium + text-muted-filled, empty
// shortest + faint border-filled. Scroll cycles tags, click jumps to one.
//
// Root is a plain Item, not a Row -- the wheel-catching MouseArea below
// needs `anchors.fill`, which QtQuick's Row positioner rejects on its own
// direct children ("Cannot specify left, right, horizontalCenter, fill or
// centerIn anchors for items inside Row", confirmed via `qs ... -n` +
// `qs ... log` on this system). tickRow does the actual horizontal layout.
Item {
    id: root

    required property string screenName
    implicitWidth: tickRow.implicitWidth
    implicitHeight: Theme.barHeight - 14

    readonly property var tags: MangoService.tagsFor(root.screenName)
    readonly property var activeIndices: MangoService.activeTagIndicesFor(root.screenName)

    Row {
        id: tickRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.tags
            delegate: Item {
                id: tick
                required property var modelData
                readonly property bool isActive: root.activeIndices.indexOf(modelData.index) !== -1
                readonly property bool isOccupied: (modelData.client_count || 0) > 0

                width: 8
                height: root.implicitHeight

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 4
                    radius: 2
                    height: tick.isActive ? parent.height : (tick.isOccupied ? parent.height * 0.6 : parent.height * 0.3)
                    scale: hoverArea.containsMouse ? 1.3 : 1.0
                    transformOrigin: Item.Bottom
                    color: tick.isActive ? Theme.accent : (tick.isOccupied ? Theme.textMuted : Theme.border)
                    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    onClicked: MangoService.viewTag(root.screenName, tick.modelData.index)
                }
            }
        }
    }

    // Scroll anywhere over the whole tick row to cycle tags, matching the
    // pill-scroll convention bars/lucid's TagsPill already established.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => MangoService.scrollTag(root.screenName, wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
