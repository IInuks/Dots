import QtQuick
import Quickshell
import Quickshell.Wayland

// One floating island as its own top-level layer-shell surface. Three of
// these (left/center/right) replace what would otherwise be one
// full-width transparent bar strip with a hand-rolled union mask -- using
// separate windows gets "wallpaper visible between islands" for free (there
// is no window there at all between them) and keeps each island's popup
// fully independent of the other two.
//
// exclusiveZone is 0 -- deliberately NOT Theme.islandHeight. mango stacks
// multiple top-anchored layer-shell surfaces by offsetting each one's
// position by the *other* surfaces' exclusive zones, the same way it would
// stack several independent bars. With three same-edge surfaces from this
// one app, that showed up as: the left island sitting visibly lower than
// center/right at rest, and islands shifting position whenever another
// island's popup changed its own height. Confirmed live by toggling
// exclusiveZone to 0 -- all three then stay independently positioned by
// their own margins alone, both at rest and while any popup is open. The
// tradeoff: mango no longer reserves top-strip space against tiled windows
// for these surfaces (existing gappoh/gappov cover most of that visually).
PanelWindow {
    id: island

    required property var modelData
    screen: modelData
    readonly property string outputName: island.screen ? island.screen.name : ""

    // "left" | "center" | "right" -- controls which screen edge this
    // window anchors to and which side the bar/popup content hugs.
    required property string side
    // { popupName: Component } -- which of PopupState's popup names belong
    // to this island, and what to show for each.
    property var popups: ({})
    // The bar row's own content (buttons/modules), set by the caller.
    default property alias barContent: barRow.data

    readonly property bool popupOpen: island.popups[PopupState.openPopup] !== undefined

    // Horizontal placement within bodyItem for a given content width, per
    // side. Plain x math instead of conditional left/right/horizontalCenter
    // anchor bindings -- QML's anchor-conflict check fires on whether a
    // binding was *given* at all, not on what it evaluates to, so a ternary
    // that resolves to `undefined` for the unused sides still counts as
    // "specified" and trips "cannot specify left, right and horizontalCenter
    // at the same time" (confirmed via the exact warning while testing this
    // file). Plain x avoids the false conflict entirely.
    function alignX(contentWidth, containerWidth) {
        if (island.side === "left") return 0;
        if (island.side === "right") return containerWidth - contentWidth;
        return (containerWidth - contentWidth) / 2;
    }

    // Only ever anchor ONE horizontal edge (or none, for "center"): PanelWindow's
    // anchors.left/right are wlr-layer-shell edge-anchor booleans, not QtQuick
    // AnchorLines -- setting *both* true stretches the surface to fill the
    // full output width (confirmed live: with both true, "center"'s content
    // rendered flush at the screen's left edge instead of centered, since a
    // stretched surface's own natural width no longer matches bodyItem's
    // content-driven width, and the alignX centering below only centers
    // content *within this window*, not the window on the screen). Anchoring
    // neither edge lets the compositor center the surface itself, which is
    // exactly the "center" behavior we want.
    anchors.top: true
    anchors.left: island.side === "left"
    anchors.right: island.side === "right"
    // TopGapReserve.qml's exclusiveZone pushes every same-edge layer-shell
    // surface down by its own height (see Theme.topReserveZone) regardless
    // of layer -- confirmed live: islands rendered ~34px lower than intended
    // until this compensated it back out. Net position: marginTop -
    // topReserveZone + topReserveZone (added by mango) = marginTop.
    margins.top: Theme.marginTop - Theme.topReserveZone
    margins.left: island.side === "left" ? Theme.marginSide : 0
    margins.right: island.side === "right" ? Theme.marginSide : 0

    color: "transparent"
    implicitWidth: bodyItem.width
    implicitHeight: bodyItem.height
    exclusiveZone: 0

    // Overlay, not Top: the click-away catcher (shell.qml) is also Top, and
    // same-layer stacking order between separate surfaces isn't guaranteed --
    // in practice the catcher (declared last, so mapped after the islands)
    // was rendering above them, swallowing every click meant for popup
    // content (sliders, list rows, buttons) as a click-away instead.
    // Overlay always stacks above Top, so islands/popups are now guaranteed
    // to receive clicks before the catcher does, regardless of map order.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "floating-" + island.side
    // Exclusive only while this island's own popup is open -- OnDemand
    // focus in mango/dwl-derived compositors is only granted on a pointer
    // click on the surface, which never happens for a popup opened purely
    // by a preceding click that already landed elsewhere in this same
    // window (established necessity, see quickbar/shell.qml).
    WlrLayershell.keyboardFocus: island.popupOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: bodyItem
        readonly property real _popupW: popupLoader.active && popupLoader.item ? popupLoader.item.implicitWidth : 0
        readonly property real _popupH: popupLoader.active && popupLoader.item ? popupLoader.item.implicitHeight : 0
        width: Math.max(barRect.width, _popupW)
        height: Theme.islandHeight + (popupLoader.active ? Theme.popupGap + _popupH : 0)

        focus: island.popupOpen
        Keys.onEscapePressed: PopupState.close()

        Rectangle {
            id: barRect
            y: 0
            x: island.alignX(width, bodyItem.width)
            width: barRow.implicitWidth + Theme.paddingHorizontal * 2
            height: Theme.islandHeight
            radius: Theme.islandRadius
            color: Theme.islandBackgroundColor
            border.width: Theme.islandBorderWidth
            border.color: Theme.islandBorderColor

            Row {
                id: barRow
                anchors.centerIn: parent
                spacing: Theme.moduleSpacing
            }
        }

        Loader {
            id: popupLoader
            active: island.popupOpen
            y: Theme.islandHeight + Theme.popupGap
            x: island.alignX(item ? item.implicitWidth : 0, bodyItem.width)
            sourceComponent: island.popups[PopupState.openPopup] || null
        }
    }
}
