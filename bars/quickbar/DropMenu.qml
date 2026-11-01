import QtQuick

// A small menu that "hangs" from the bar's bottom edge, using the same
// HangingShape as the bar (just smaller flares). Positioned by the caller
// via `targetX` (desired left edge of the whole shape, including its own
// flares) + `boundsWidth` (the bar's body width) -- clamped internally so
// the menu's own flares never poke out past the bar's rounded bottom
// corners. Height animates from 0; width is fixed per-menu. The caller
// overlaps this 1-2px up into the bar (negative anchors.topMargin) so the
// flush top edges don't show a seam.
Item {
    id: root

    property string menuName: ""
    property real menuWidth: 200
    property real contentHeight: 100
    property real flareW: 16
    property real flareH: 16
    property real bottomRadius: 18

    property real targetX: 0
    property real boundsWidth: 0

    default property alias content: inner.data

    readonly property bool isOpen: MenuState.openMenu === root.menuName

    width: menuWidth + 2 * flareW
    x: Math.max(0, Math.min(targetX, root.boundsWidth - root.width))
    height: isOpen ? contentHeight : 0
    clip: true
    visible: height > 0

    Behavior on height { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    HangingShape {
        bodyWidth: root.menuWidth
        bodyHeight: Math.max(root.contentHeight, 1)
        flareW: root.flareW
        flareH: root.flareH
        bottomRadius: root.bottomRadius
        fillColor: Theme.surface
    }

    Item {
        id: inner
        x: root.flareW
        y: 0
        width: root.menuWidth
        height: root.contentHeight
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Keys.onEscapePressed: MenuState.close()
}
