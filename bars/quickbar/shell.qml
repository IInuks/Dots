import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property int barHeight: 48
    property int barPadding: 16
    property int itemSpacing: 16
    property int bigMenuHeight: 480
    property int barFlareW: 30
    property int barFlareH: 22
    property int barBottomRadius: 22

    // External trigger for keybinds, e.g. `qs -p .../quickbar ipc call launcher toggle`
    IpcHandler {
        target: "launcher"
        function toggle(): void { MenuState.toggle("launcher"); }
        function open(): void { MenuState.open("launcher"); }
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notif => {
            notif.tracked = true;
            NotificationState.push({
                id: notif.id,
                appName: notif.appName,
                appIcon: notif.appIcon,
                summary: notif.summary,
                body: notif.body,
                urgency: notif.urgency
            }, notif);
            notif.closed.connect(() => NotificationState.removeOnly(notif.id));
        }
    }

    // Outside-click catcher: a separate, permanently fullscreen surface
    // with NO exclusive zone, so it never confuses window tiling. Declared
    // first so it stacks below the bar window on this layer. Fully
    // click-through when idle; only catches clicks (to close the open
    // menu) while one is open.
    PanelWindow {
        id: catcher
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickbar-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: MenuState.anyOpen ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        MouseArea {
            anchors.fill: parent
            enabled: MenuState.anyOpen
            onClicked: MenuState.close()
        }
    }

    // The bar itself. Permanently anchored to just the top strip (never
    // the opposite edge) so exclusiveZone stays unambiguous and windows
    // reliably avoid it. Sized to the big menu's height from the start
    // (per spec) so it never has to resize during animations -- only the
    // visible shapes within it grow/shrink.
    PanelWindow {
        id: win
        anchors { top: true; left: true; right: true }
        implicitHeight: root.bigMenuHeight
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickbar"
        // OnDemand focus in mango/dwl-derived compositors is typically only
        // granted on a pointer click on the surface -- which never happens
        // when a menu is opened via a keybind (SUPER+space spawns an IPC
        // call, no click involved), so Esc/typing silently went nowhere.
        // Exclusive is unconditional: the compositor must hand us keyboard
        // input the moment we ask, regardless of how the menu was opened.
        WlrLayershell.keyboardFocus: MenuState.anyOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusiveZone: root.barHeight

        // Only the bar shape, plus whichever drop-menu is currently open,
        // accepts clicks -- everything else is click-through (the catcher
        // window above handles "click elsewhere closes the menu").
        readonly property real openDropMenuHeight: MenuState.openMenu === "power" ? powerMenu.height
            : MenuState.openMenu === "launcher" ? launcherMenu.height : 0
        readonly property real openDropMenuRadius: MenuState.openMenu === "power" ? powerMenu.bottomRadius
            : MenuState.openMenu === "launcher" ? launcherMenu.bottomRadius : root.barBottomRadius

        mask: Region {
            id: barMask
            x: shapeWrap.x
            y: shapeWrap.y
            width: shapeWrap.width
            height: shapeWrap.height + win.openDropMenuHeight
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: win.openDropMenuHeight > 0 ? win.openDropMenuRadius : root.barBottomRadius
            bottomRightRadius: win.openDropMenuHeight > 0 ? win.openDropMenuRadius : root.barBottomRadius
        }

        Item {
            id: scene
            anchors.fill: parent

            Item {
                anchors.fill: parent
                focus: MenuState.anyOpen
                Keys.onEscapePressed: MenuState.close()
            }

            Item {
                id: shapeWrap
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: hangingShape.width
                height: hangingShape.height

                HangingShape {
                    id: hangingShape
                    bodyWidth: row.implicitWidth + root.barPadding * 2
                    bodyHeight: MenuState.openMenu === "big" ? root.bigMenuHeight : root.barHeight
                    flareW: root.barFlareW
                    flareH: root.barFlareH
                    bottomRadius: root.barBottomRadius
                    fillColor: Theme.surface
                    Behavior on bodyWidth { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                    Behavior on bodyHeight { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                }

                Item {
                    id: content
                    x: root.barFlareW
                    y: 0
                    width: hangingShape.bodyWidth
                    height: hangingShape.bodyHeight

                Row {
                    id: row
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: root.barHeight
                    spacing: root.itemSpacing
                    opacity: MenuState.openMenu === "big" ? 0 : 1
                    enabled: MenuState.openMenu !== "big"
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                    PowerButton {
                        id: powerBtn
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: MenuState.toggle("power")
                    }
                    CpuUsage { anchors.verticalCenter: parent.verticalCenter }
                    MicButton { anchors.verticalCenter: parent.verticalCenter }
                    WindowList { anchors.verticalCenter: parent.verticalCenter }
                    Workspaces { anchors.verticalCenter: parent.verticalCenter }
                    Launcher { id: launcher; anchors.verticalCenter: parent.verticalCenter }
                    ClockModule {
                        id: clockBtn
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: MenuState.toggle("big")
                    }
                }

                DropMenu {
                    id: powerMenu
                    menuName: "power"
                    menuWidth: 170
                    contentHeight: 3 * 34 + 12
                    anchors.top: parent.bottom
                    anchors.topMargin: -1
                    boundsWidth: content.width
                    targetX: row.x + powerBtn.x + powerBtn.width / 2 - width / 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        MenuButton {
                            label: "Herunterfahren"; iconName: "power"; tint: Theme.danger
                            onActivated: { MenuState.close(); Quickshell.execDetached(["systemctl", "poweroff"]); }
                        }
                        MenuButton {
                            label: "Neustarten"; iconName: "restart"
                            onActivated: { MenuState.close(); Quickshell.execDetached(["systemctl", "reboot"]); }
                        }
                        MenuButton {
                            label: "Abmelden"; iconName: "logout"
                            onActivated: { MenuState.close(); Quickshell.execDetached(["mmsg", "dispatch", "quit"]); }
                        }
                    }
                }

                DropMenu {
                    id: launcherMenu
                    menuName: "launcher"
                    menuWidth: 260
                    contentHeight: Math.max(launcher.results.length, 1) * 32 + 12
                    anchors.top: parent.bottom
                    anchors.topMargin: -1
                    boundsWidth: content.width
                    targetX: row.x + launcher.x + launcher.width / 2 - width / 2

                    Item {
                        anchors.fill: parent
                        anchors.margins: 6

                        Text {
                            visible: launcher.results.length === 0
                            anchors.centerIn: parent
                            text: launcher.query.length === 0 ? "Tippen zum Suchen…" : "Keine Treffer"
                            color: Theme.textDim
                            font.pixelSize: 12
                            font.italic: true
                        }

                        LauncherResults {
                            width: parent.width
                            results: launcher.results
                            query: launcher.query
                            selectedIndex: launcher.selectedIndex
                        }
                    }
                }

                BigMenu {
                    stripHeight: root.barHeight
                }
                }
            }
        }
    }
}
