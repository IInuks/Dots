import QtQuick
import Quickshell
import Quickshell.Wayland

// Reserves top-edge workarea space for the floating islands via layer-shell
// exclusiveZone, so tiled windows start below the bar instead of relying on
// mango's gappov (which is symmetric top+bottom -- see conversation, no
// per-edge gap exists in mango, so any value that clears the bar at the top
// also inflates the bottom gap by the same amount).
//
// A dedicated, invisible, always-click-through surface rather than putting
// exclusiveZone on the islands themselves: IslandBase.qml already documents
// that mango stacks multiple top-anchored layer-shell surfaces by offsetting
// each one's position by the *other* surfaces' exclusive zones, which is why
// the three islands run at exclusiveZone 0. A single reservation surface hits
// the same offsetting behavior for anything sharing its layer+edge, so this
// is deliberately WlrLayer.Bottom -- a different layer from the islands
// (Overlay) -- on the hypothesis that mango's same-edge offset stacking is
// scoped per layer, not global, while exclusiveZone's contribution to the
// compositor's tiled-window workarea is honored regardless of layer. Confirm
// live: islands should stay at their ~6px marginTop, and tiled windows
// should start clear of the bar at the top without touching gappov.
PanelWindow {
    id: reserve

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.topReserveZone

    color: "transparent"
    exclusiveZone: Theme.topReserveZone

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "floating-topgap"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: emptyRegion
    Region { id: emptyRegion; width: 0; height: 0 }
}
