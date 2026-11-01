import QtQuick

// 9 mango tags, 4 visible at a time. The visible window slides just enough
// to keep the active tag in view; a separate colored indicator glides
// (with a slight spring) to the active tag's slot.
Item {
    id: root

    readonly property int tagCount: 9
    readonly property int visibleCount: 4
    readonly property real slotWidth: 30
    readonly property real spacing: 6
    readonly property real step: slotWidth + spacing

    implicitWidth: visibleCount * slotWidth + (visibleCount - 1) * spacing
    implicitHeight: 22

    property int windowStart: 1 // 1-based, first visible tag index

    function _clampWindow(w) {
        return Math.min(Math.max(w, 1), tagCount - visibleCount + 1);
    }

    Connections {
        target: MangoState
        function onActiveTagIndexChanged() {
            const active = MangoState.activeTagIndex;
            let w = root.windowStart;
            if (active < w) w = active;
            else if (active > w + root.visibleCount - 1) w = active - root.visibleCount + 1;
            root.windowStart = root._clampWindow(w);
        }
    }

    Item {
        id: viewport
        anchors.fill: parent
        clip: true

        Rectangle {
            id: indicator
            width: root.slotWidth
            height: 4
            radius: 2
            y: root.height - height
            color: Theme.accent
            x: (MangoState.activeTagIndex - root.windowStart) * root.step
            Behavior on x { SpringAnimation { spring: 2.8; damping: 0.32 } }
        }

        Row {
            id: row
            spacing: root.spacing
            x: -(root.windowStart - 1) * root.step
            Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

            Repeater {
                model: root.tagCount
                delegate: Rectangle {
                    id: slot
                    required property int index
                    readonly property int tagIndex: index + 1
                    readonly property var tagData: MangoState.tags.find(t => t.index === tagIndex)
                    readonly property bool occupied: tagData ? tagData.client_count > 0 : false
                    readonly property bool active: tagIndex === MangoState.activeTagIndex

                    width: root.slotWidth
                    height: root.height - 6
                    y: 0
                    radius: Theme.radiusSmall
                    color: active ? Theme.surfaceAlt : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 5
                        height: 5
                        radius: 2.5
                        color: slot.occupied ? Theme.text : Theme.textDim
                        opacity: slot.occupied ? 0.9 : 0.4
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MangoState.viewTag(slot.tagIndex)
                    }
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
