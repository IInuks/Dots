import QtQuick

// Mango tags 1-5 as pill slots. The active slot's fill is a spring-driven
// "liquid" blob: a bright core plus a slightly larger, delayed, dimmer
// ghost trailing behind it, so the indicator visibly overshoots and
// settles instead of just sliding.
Item {
    id: root

    readonly property int tagCount: 5
    readonly property real slotSize: 22
    readonly property real spacing: 5

    implicitWidth: tagCount * slotSize + (tagCount - 1) * spacing
    implicitHeight: slotSize

    readonly property int activeIndex: Math.min(MangoState.activeTagIndex, tagCount) - 1
    readonly property real slotX: activeIndex * (slotSize + spacing)

    Rectangle {
        id: ghost
        width: root.slotSize
        height: root.slotSize
        radius: width / 2
        color: Theme.accent2
        opacity: 0.28
        x: root.slotX
        y: 0
        Behavior on x { SpringAnimation { spring: 1.4; damping: 0.5 } }
    }

    Rectangle {
        id: blob
        width: root.slotSize
        height: root.slotSize
        radius: width / 2
        color: Theme.accent
        x: root.slotX
        y: 0
        Behavior on x { SpringAnimation { spring: 2.6; damping: 0.4 } }
        Behavior on color { ColorAnimation { duration: Theme.animSlow } }
    }

    Row {
        spacing: root.spacing

        Repeater {
            model: root.tagCount
            delegate: Item {
                id: slot
                required property int index
                readonly property int tagIndex: index + 1
                readonly property var tagData: MangoState.tags.find(t => t.index === tagIndex)
                readonly property bool occupied: tagData ? tagData.client_count > 0 : false
                readonly property bool active: tagIndex === MangoState.activeTagIndex

                width: root.slotSize
                height: root.slotSize

                Text {
                    anchors.centerIn: parent
                    text: slot.tagIndex
                    color: slot.active ? Theme.bg : (slot.occupied ? Theme.text : Theme.textDim)
                    font.pixelSize: 12
                    font.bold: slot.active
                    Behavior on color { ColorAnimation { duration: Theme.animMed } }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: 4; height: 4; radius: 2
                    color: Theme.accent2
                    visible: slot.occupied && !slot.active
                    scale: visible ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: MangoState.viewTag(slot.tagIndex)
                    scale: hoverArea.containsMouse && !slot.active ? 1.15 : 1
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const dir = wheel.angleDelta.y > 0 ? -1 : 1;
            const next = Math.min(Math.max(MangoState.activeTagIndex + dir, 1), root.tagCount);
            MangoState.viewTag(next);
        }
    }
}
