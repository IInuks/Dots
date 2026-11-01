import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets/common"
import "../menus"

// Own layer-shell surface for the app launcher, instantiated fresh (by
// Bar.qml's Loader) every time it opens, instead of living as an Item
// inside the Bar's own always-mapped PanelWindow the way the other five
// popups do (see PopupShell.qml).
//
// Reason: mango only grants keyboard focus to an on-demand layer surface
// in two places -- a surface's very first ever commit (right before it
// maps), or a pointer-button-press evaluated against a keyboard_interactive
// state that's *already* committed as on-demand. Toggling
// WlrLayershell.keyboardFocus on the long-lived Bar surface always lands
// one commit too late for the very click that opens the popup (mango
// checks the state that was current *before* the click), and the
// SUPER+space hotkey path (LauncherState, no pointer click at all) can
// never trigger the pointer-side grant in the first place -- so neither
// typing nor Escape ever reached LauncherMenu. A brand-new surface's
// initial_commit grants focus immediately, regardless of which path opened
// it, so keyboardFocus is simply OnDemand from the start here.
PanelWindow {
    id: root

    required property var modelData
    // Not named `closed` -- Window already declares that as its own
    // property-change signal (fires when the window closes), and QML
    // rejects redeclaring it.
    signal closeRequested

    screen: modelData
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "fisheye-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.left: true
    margins.top: Theme.barHeight + Theme.gap * 0.4
    margins.left: Theme.gap

    implicitWidth: 240
    implicitHeight: 250

    // No grow/height animation like PopupShell's other five menus -- this
    // is a real standalone surface, not an Item inside an already-mapped
    // window, so it exists at full size from its very first frame. A
    // slide+scale+fade on its content is the cheap approximation that
    // doesn't require animating the layer-shell surface's own geometry
    // (Window itself has no `opacity`/`x`/`y` the way an Item does). Only
    // covers the open direction -- LauncherWindow is destroyed the instant
    // bar.openPopup clears (see this file's own top comment for why a
    // fresh surface is required every time), so there's no window left
    // alive to play a symmetric close animation on.
    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        y: -14
        scale: 0.92
        transformOrigin: Item.Top

        ParallelAnimation {
            running: true
            NumberAnimation {
                target: content
                property: "opacity"
                to: 1
                duration: Theme.durBase
                easing.type: Theme.easeOut
            }
            NumberAnimation {
                target: content
                property: "y"
                to: 0
                duration: Theme.durSlow
                easing.type: Theme.easeOutBack
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 1
                duration: Theme.durSlow
                easing.type: Theme.easeOutBack
            }
        }

        LcdSurface {
            anchors.fill: parent
        }
        BevelPanel {
            anchors.fill: parent
        }

        LauncherMenu {
            anchors.fill: parent
            anchors.margins: Theme.gap
            active: true
            onClosed: root.closeRequested()
        }
    }
}
