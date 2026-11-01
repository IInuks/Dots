import QtQuick
import ".."

// Mango workspace strip. Default (groupSize 1): one slot per tag that's
// active or occupied (empty, non-active tags are skipped to stay compact),
// click to switch, wheel to step -- same as always. groupSize > 1 replaces
// that row with a single "start-end" range chip for whichever group
// currently contains the active tag (e.g. "1-3" for groupSize 3), so the
// module stays compact even with many tags; click/wheel then step to the
// next/previous group's first tag instead of the next/previous tag.
Item {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    // Mango's tag count is fixed at 9 (see the wheel-clamp below, unchanged
    // from before grouping existed) -- groups are computed against that,
    // not against however many tags happen to be occupied right now.
    readonly property int maxTag: 9
    readonly property int groupSize: Math.max(1, settings.groupSize || 1)
    readonly property bool grouped: root.groupSize > 1

    readonly property var visibleTags: (MangoIpc.tags || []).filter(t => t.is_active || t.client_count > 0)

    function groupIndexOf(tagIndex) {
        return Math.floor((tagIndex - 1) / root.groupSize);
    }
    function groupStart(g) {
        return g * root.groupSize + 1;
    }
    function groupEnd(g) {
        return Math.min(root.groupStart(g) + root.groupSize - 1, root.maxTag);
    }
    readonly property int totalGroups: Math.ceil(root.maxTag / root.groupSize)
    readonly property int activeGroup: root.groupIndexOf(MangoIpc.activeTagIndex)
    readonly property string groupLabel: {
        const s = root.groupStart(root.activeGroup), e = root.groupEnd(root.activeGroup);
        return s === e ? String(s) : (s + "-" + e);
    }

    function stepGroup(dir) {
        const ng = (root.activeGroup + dir + root.totalGroups) % root.totalGroups;
        MangoIpc.viewTag(root.groupStart(ng));
    }

    implicitWidth: root.grouped ? groupChip.width : row.implicitWidth
    implicitHeight: root.grouped ? groupChip.height : row.implicitHeight

    // -- Ungrouped: one slot per occupied/active tag -----------------------
    Row {
        id: row
        visible: !root.grouped
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.visibleTags
            delegate: Rectangle {
                id: slot
                required property var modelData
                width: 20
                height: 20
                radius: 5
                color: modelData.is_active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3) : "transparent"
                border.width: modelData.is_active ? 1 : 0
                border.color: root.accent

                Text {
                    anchors.centerIn: parent
                    text: slot.modelData.index
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize - 2
                    color: root.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MangoIpc.viewTag(slot.modelData.index)
                }
            }
        }
    }

    // -- Grouped: single range chip for the active group --------------------
    Rectangle {
        id: groupChip
        visible: root.grouped
        anchors.centerIn: parent
        width: groupLabelText.implicitWidth + 16
        height: 20
        radius: 6
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)
        border.width: 1
        border.color: root.accent

        Text {
            id: groupLabelText
            anchors.centerIn: parent
            text: root.groupLabel
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 2
            color: root.foreground
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.stepGroup(1)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const dir = wheel.angleDelta.y > 0 ? -1 : 1;
            if (root.grouped) {
                root.stepGroup(dir);
            } else {
                const next = Math.min(Math.max(MangoIpc.activeTagIndex + dir, 1), root.maxTag);
                MangoIpc.viewTag(next);
            }
        }
    }
}
