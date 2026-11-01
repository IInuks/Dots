import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// fullshell: one floating capsule bar (Workspaces/Tray/CPU/Battery/Volume/
// Clock/Orb) plus a single big "Command Center" overlay housing the app
// launcher, wallpaper switcher, theme/transparency controls, system info
// and power actions -- everything animated (springs, breathing glows,
// staggered entrances) rather than snapping.
ShellRoot {
    id: root

    readonly property int barHeight: 34
    readonly property int barTopMargin: 10
    readonly property int barSidePadding: 20
    readonly property int barSpacing: 16

    IpcHandler {
        target: "menu"
        function toggle(): void { MenuState.toggleDefault(); }
        function open(): void { MenuState.openAt(MenuState.activeTab); }
        function close(): void { MenuState.close(); }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (MenuState.open && MenuState.activeTab === MenuState.tabApps) MenuState.close();
            else MenuState.openLauncher();
        }
        function open(): void { MenuState.openLauncher(); }
        function close(): void { if (MenuState.activeTab === MenuState.tabApps) MenuState.close(); }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (MenuState.open && MenuState.activeTab === MenuState.tabWallpaper) MenuState.close();
            else MenuState.openWallpaper();
        }
        function open(): void { MenuState.openWallpaper(); }
        function close(): void { if (MenuState.activeTab === MenuState.tabWallpaper) MenuState.close(); }
    }

    // Full-screen overlay hosting the Command Center. Click-through when
    // closed (empty mask), fully modal when open (null mask + exclusive
    // keyboard focus) so Esc/typing and outside-click-to-close work.
    PanelWindow {
        id: overlayWin
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "fullshell-overlay"
        WlrLayershell.keyboardFocus: MenuState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: MenuState.open ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        CommandCenter {}
    }

    // The bar itself: a small strip reserved via exclusiveZone, but only
    // the pill shape (not the full strip width) actually accepts clicks.
    PanelWindow {
        id: barWin
        anchors { top: true; left: true; right: true }
        implicitHeight: root.barTopMargin + root.barHeight + 10
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "fullshell-bar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: implicitHeight

        mask: Region {
            x: pill.x
            y: pill.y
            width: pill.width
            height: pill.height
            topLeftRadius: Theme.radiusPill
            topRightRadius: Theme.radiusPill
            bottomLeftRadius: Theme.radiusPill
            bottomRightRadius: Theme.radiusPill
        }

        Item {
            id: pill
            anchors.top: parent.top
            anchors.topMargin: root.barTopMargin
            anchors.horizontalCenter: parent.horizontalCenter
            width: content.implicitWidth + root.barSidePadding * 2
            height: root.barHeight

            // Entrance: drops in from above with a fade + slight overshoot
            // the moment the shell starts.
            property real entranceProgress: 0
            y: (1 - entranceProgress) * -30
            opacity: entranceProgress
            Component.onCompleted: entranceAnim.start()
            NumberAnimation {
                id: entranceAnim
                target: pill
                property: "entranceProgress"
                from: 0; to: 1
                duration: 650
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }

            PillSurface {
                anchors.fill: parent
                glow: true
            }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: root.barSpacing

                Workspaces { anchors.verticalCenter: parent.verticalCenter }
                Tray { anchors.verticalCenter: parent.verticalCenter; hostWindow: barWin }
                CpuUsage { anchors.verticalCenter: parent.verticalCenter; onClicked: MenuState.openAt(MenuState.tabSystem) }
                Battery { anchors.verticalCenter: parent.verticalCenter; onClicked: MenuState.openAt(MenuState.tabSystem) }
                Volume { anchors.verticalCenter: parent.verticalCenter; onClicked: MenuState.openAt(MenuState.tabSystem) }
                Clock { anchors.verticalCenter: parent.verticalCenter; onClicked: MenuState.openAt(MenuState.tabSystem) }
                Orb { anchors.verticalCenter: parent.verticalCenter; onClicked: MenuState.toggleDefault() }
            }
        }
    }
}
