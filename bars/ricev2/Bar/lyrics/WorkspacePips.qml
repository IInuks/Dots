import QtQuick
import "../../"

// Idle-state content of the middle island (see LyricsIsland.qml): while
// no MPRIS player is active, the middle island now stays visible and
// shows mango's tags/workspaces here instead of going empty. Live data
// from MangoState.qml (`mmsg watch all-monitors`, same subscription
// bars/quickbar's MangoState.qml already uses on this system).
//
// Deliberately its own look, not a copy of bars/rice/Bar/WorkspacePips.qml's
// ticks: a sliding highlight capsule slides/bounces (OutBack) behind
// whichever pip is active instead of just resizing that one tick in place,
// since this island already has room to spare and the user asked for
// "schöne Animationen".
//
// Style picker: Config.workspaceStyle ("dots" | "numbers" | "roman" |
// "bars"), set via Bar/menus/SettingsDropdown.qml. "dots" is the original
// look above, unchanged. The other three keep the same highlight capsule/
// hover/click/scroll mechanics, just change how each pip itself renders --
// see the `dot` Rectangle below for the shared per-style geometry (also
// mirrored, scaled down, in Bar/menus/WorkspaceStylePreview.qml's picker
// previews).
Item {
    id: root

    readonly property var tags: MangoState.tags
    readonly property string style: Config.workspaceStyle
    readonly property int pipSize: 18
    readonly property int pipSpacing: 8

    implicitWidth: pipRow.implicitWidth
    implicitHeight: root.pipSize

    readonly property int _activeVisualIndex: {
        for (let i = 0; i < root.tags.length; i++)
            if (root.tags[i].index === MangoState.activeTagIndex)
                return i;
        return -1;
    }

    function _toRoman(num) {
        const vals = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        let n = Math.max(0, Math.floor(num));
        let out = "";
        for (const [v, s] of vals) {
            while (n >= v) {
                out += s;
                n -= v;
            }
        }
        return out || "0";
    }

    // Sliding highlight capsule, behind the pip row (z default 0 vs. 1).
    // Rounder for dots/numbers/roman (pill, matches their circular pips),
    // a softer rounded-rect for bars (matches the vertical-bar look).
    Rectangle {
        id: highlight
        y: 0
        width: root.pipSize + 10
        height: root.pipSize + 10
        anchors.verticalCenter: pipRow.verticalCenter
        radius: root.style === "bars" ? Style.radius8 : height / 2
        visible: root._activeVisualIndex >= 0
        x: root._activeVisualIndex >= 0 ? root._activeVisualIndex * (root.pipSize + root.pipSpacing) - 5 : 0
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)

        Behavior on x {
            NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
        Behavior on opacity {
            NumberAnimation { duration: Style.anim200; easing.type: Easing.OutCubic }
        }
    }

    Row {
        id: pipRow
        spacing: root.pipSpacing

        Repeater {
            model: root.tags

            Item {
                id: pip
                required property var modelData
                readonly property bool isActive: modelData.is_active === true
                readonly property bool isOccupied: (modelData.client_count || 0) > 0
                readonly property bool isUrgent: modelData.is_urgent === true

                width: root.pipSize
                height: root.pipSize

                readonly property bool isBars: root.style === "bars"
                readonly property bool showsText: root.style === "numbers" || root.style === "roman"

                Rectangle {
                    id: dot
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: pip.isBars ? undefined : parent.verticalCenter
                    anchors.bottom: pip.isBars ? parent.bottom : undefined
                    radius: pip.isBars ? 3 : width / 2
                    width: {
                        if (pip.isBars)
                            return root.pipSize * 0.5;
                        if (pip.showsText)
                            return root.pipSize;
                        return pip.isActive ? root.pipSize : (pip.isOccupied ? root.pipSize * 0.6 : root.pipSize * 0.4);
                    }
                    height: pip.isBars ? (pip.isActive ? root.pipSize * 1.3 : (pip.isOccupied ? root.pipSize * 0.8 : root.pipSize * 0.45)) : dot.width
                    scale: pipHover.hovered ? 1.2 : 1.0
                    color: pip.isUrgent ? Colors.error : (pip.isActive ? Colors.primary : (pip.isOccupied ? Colors.tertiary : "transparent"))
                    border.width: (pip.isActive || pip.isOccupied || pip.isUrgent) ? 0 : 1.5
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.6)

                    Behavior on width { NumberAnimation { duration: Style.anim200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    Behavior on height { NumberAnimation { duration: Style.anim200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    Behavior on scale { NumberAnimation { duration: Style.anim150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Style.anim200 } }

                    Text {
                        anchors.centerIn: parent
                        visible: !pip.isBars && (pip.showsText || pip.isActive)
                        text: root.style === "roman" ? root._toRoman(pip.modelData.index) : String(pip.modelData.index)
                        font.family: Style.textFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: !pip.showsText ? Colors.primaryText : (pip.isActive ? Colors.primaryText : (pip.isOccupied ? Colors.surface : Colors.backgroundText))
                        opacity: pip.showsText ? 1 : (dot.width >= root.pipSize * 0.9 ? 1 : 0)
                        Behavior on opacity { NumberAnimation { duration: Style.anim150 } }
                    }
                }

                HoverHandler {
                    id: pipHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MangoState.viewTag(pip.modelData.index)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: pipRow
        acceptedButtons: Qt.NoButton
        onWheel: wheel => MangoState.scrollTag(wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
