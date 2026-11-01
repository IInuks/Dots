import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants { model: Quickshell.screens; delegate: TopReserve {} }
    Variants { model: Quickshell.screens; delegate: LeftCluster {} }
    Variants { model: Quickshell.screens; delegate: CenterCluster {} }
    Variants { model: Quickshell.screens; delegate: RightCluster {} }

    // Click-away dismissal: an always-present, click-through-when-idle
    // fullscreen surface. Sits on the same layer as the clusters (Top) so
    // it renders/receives input *below* the Overlay-layer popups -- a click
    // on a popup still reaches the popup's own controls, anything else
    // reaches this and closes whatever's open.
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "weich-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: PopupState.anyOpen ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        MouseArea {
            anchors.fill: parent
            enabled: PopupState.anyOpen
            onClicked: PopupState.close()
        }
    }
}
