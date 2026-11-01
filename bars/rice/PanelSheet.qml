import QtQuick
import Quickshell
import Quickshell.Wayland

// Shared sheet chrome for every panel (ControlCenter, Wallpaper-Switcher,
// PowerMenu): a full-screen overlay layer-shell surface, a click-to-close
// scrim, and one rounded panel docked just below the (top) bar that drops
// down/retracts up. `open` toggles the WHOLE window's `visible` (never
// mapped at all while closed), so none of the oversized-window mask
// pitfall applies here (feedback_quickshell_panelwindow_mask_input_
// region) -- unlike bars/lucid's always-mapped bar window with popups
// inside it, this window simply doesn't exist on the compositor side
// while closed.
//
// Anchored to the primary screen only (Quickshell.screens[0]) -- a known
// Stage 1 simplification for multi-monitor setups, see README "Bekannte
// Lücken".
//
// default property alias redirects a composed file's declared children
// (e.g. Panels/ControlCenter.qml's `PanelSheet { Column { ... } }`) into
// `contentHolder` instead of becoming direct PanelWindow children.
PanelWindow {
    id: sheet

    default property alias data: contentHolder.data

    required property bool open
    property int sheetWidth: 380
    property int sheetHeight: 420
    // "right" docks sheetWidth-wide above the bar's right cluster,
    // "stretch" spans the full width minus sideMargin on both sides
    // (WallpaperSwitcher).
    property string horizontalAlign: "right"
    property int sideMargin: 16

    screen: Quickshell.screens[0] ?? null
    visible: sheet.open
    color: "transparent"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: -1 // overlay -- never pushes the bar or tiled windows

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-sheet"
    // OnDemand from creation, never toggled after -- mango only grants
    // keyboard focus at a surface's initial_commit or on a click already
    // committed as OnDemand, never on a later None->OnDemand flip of a
    // reused surface (memory: feedback_mango_ondemand_focus_requires_
    // fresh_surface). This window IS freshly (re)mapped every open (see
    // `visible` above), so OnDemand here is actually fresh each time.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: sheet.open ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
        MouseArea {
            anchors.fill: parent
            onClicked: PanelState.close()
        }
    }

    Rectangle {
        id: contentHolder
        width: sheet.horizontalAlign === "stretch" ? parent.width - sheet.sideMargin * 2 : sheet.sheetWidth
        height: sheet.sheetHeight
        radius: Theme.sheetRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        clip: true

        anchors.right: sheet.horizontalAlign !== "center" ? parent.right : undefined
        anchors.rightMargin: sheet.horizontalAlign === "right" ? sheet.sideMargin : 0
        anchors.horizontalCenter: sheet.horizontalAlign === "center" ? parent.horizontalCenter : undefined

        // Docks just BELOW the (top) bar and drops down when opened --
        // mirror of the original bottom-bar version, which docked above
        // the bar via anchors.bottom/bottomMargin. Flipped 2026-09-21 when
        // the bar itself moved from bottom to top (Bar/Bar.qml).
        anchors.top: parent.top
        anchors.topMargin: sheet.open ? (Theme.barHeight + 10) : -(sheet.sheetHeight + 40)
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

        // Consumes clicks so they don't fall through to the scrim beneath
        // and close the panel while interacting with its own content.
        MouseArea { anchors.fill: parent; onClicked: mouse => {} }
    }
}
