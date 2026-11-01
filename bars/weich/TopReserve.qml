import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible top-edge exclusive-zone reservation so tiled windows stay clear
// of the bar. mango offsets every same-edge layer-shell surface's position
// by the *other* same-edge surfaces' exclusiveZone -- scoped per layer, not
// global -- so this sits on WlrLayer.Bottom, a different layer from the
// cluster windows (Top), while still counting toward the compositor's tiled
// workarea regardless of layer. The clusters compensate for their own
// leftover offset by subtracting Theme.topReserve back out of margins.top.
PanelWindow {
    property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.topReserve
    color: "transparent"
    exclusiveZone: Theme.topReserve

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "weich-top-reserve"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: emptyRegion
    Region { id: emptyRegion; width: 0; height: 0 }
}
