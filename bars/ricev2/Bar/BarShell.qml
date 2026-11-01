import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// Bar prompt section 1 (Fenster) + section 8 (Verhalten), Stage 1 slice.
// classic-only for now (pill style is section 2's "Alternativer Stil",
// deferred -- see README).
PanelWindow {
    id: barWindow

    readonly property int barHeight: Style.barHeight
    // classic style shifts the bar up 1px so there's no seam against the
    // screen edge (spec section 2).
    readonly property int topMargin: -1

    screen: {
        const named = Quickshell.screens.find(s => s.name === Config.monitorName);
        return named ? named : Quickshell.screens[0];
    }

    WlrLayershell.namespace: "topbar"
    WlrLayershell.layer: WlrLayer.Top
    // Exclusive while any bar dropdown is open (not just the WLAN password
    // field's DropdownState.keyboardWanted case) -- needed so Esc reliably
    // closes it (see TopBar.qml's dropdownEscCatcher) instead of depending
    // on OnDemand's unverified click-grant behavior (memory:
    // feedback_mango_ondemand_focus_requires_fresh_surface). OnDemand only
    // while nothing is open, so a plain click-to-open still doesn't steal
    // focus from whatever's underneath beforehand.
    WlrLayershell.keyboardFocus: DropdownState.open !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    // Window height grows to cover an open dropdown (Stage 3) on top of the
    // bar strip -- topBar.implicitHeight is barHeight + whatever dropdown
    // is currently open (0 when none). exclusiveZone stays pinned to just
    // the bar strip so an open dropdown overlays windows below instead of
    // pushing them down.
    implicitHeight: topBar.implicitHeight

    exclusiveZone: Config.barVisible ? (barHeight + topMargin) : 0

    Item {
        id: content
        anchors.fill: parent
        y: Config.barVisible ? topMargin : -(barHeight + topMargin)
        Behavior on y {
            NumberAnimation { duration: Style.anim150; easing.type: Easing.OutQuad }
        }

        TopBar {
            id: topBar
            anchors.fill: parent
        }
    }

    // Only the island shapes (and, later, open dropdowns) are clickable;
    // everywhere else in this window's geometry clicks through to
    // whatever's underneath (memory:
    // feedback_quickshell_panelwindow_mask_input_region -- a PanelWindow
    // without an explicit mask swallows clicks across its whole rect).
    mask: Region {
        Region { item: topBar.leftIslandItem }
        Region { item: topBar.rightIslandItem }
        Region { item: topBar.middleIslandItem }
        // Dropdown.qml already collapses to 0 height while closed (memory:
        // feedback_quickshell_panelwindow_mask_input_region -- `visible`
        // alone wouldn't shrink this region), so this never adds a dead
        // click zone under the bar when nothing is open.
        Region { item: topBar.dropdownItem }
        // Left-island counterpart (sysmonitor) -- same reasoning, easy to
        // miss since it's a second Dropdown instance the mask needs telling
        // about separately (memory: feedback_quickshell_panelwindow_mask_input_region).
        Region { item: topBar.leftDropdownItem }
    }

    // qs -p <dir> ipc call bar toggle|show|hide -- state survives restarts
    // via ~/.cache/ricev2/bar-state (spec section 8).
    IpcHandler {
        target: "bar"
        function toggle(): void { Config.setBarVisible(!Config.barVisible); barState.write(); }
        function show(): void { Config.setBarVisible(true); barState.write(); }
        function hide(): void { Config.setBarVisible(false); barState.write(); }
    }

    FileView {
        id: barState
        path: Quickshell.env("HOME") + "/.cache/ricev2/bar-state"
        printErrors: false
        function write(): void {
            setText(Config.barVisible ? "visible" : "hidden");
        }
        onLoaded: {
            const t = text().trim();
            if (t === "hidden" || t === "visible") {
                Config.setBarVisible(t === "visible");
            }
        }
    }
}
