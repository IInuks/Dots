//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "services"
import "components"
import "modules/popups"
import "modules/launcher"

// Launcher-only host for bars/kurtz (see the menu README, "Launcher
// mischen"): kurtz's per-screen Overlay.qml with only the launcher in it
// -- both styles (list card and "orbit"), whichever Config.s.launcherStyle
// picks. No bar, toasts, OSD or other popups.
ShellRoot {
    id: shell

    function focusedScreen() {
        const m = Tags.monitors.find(x => x.active);
        return m ? m.name : (Quickshell.screens[0] ? Quickshell.screens[0].name : "");
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Popups.toggle("launcher", shell.focusedScreen(), -1); }
        function open(): void { Popups.open("launcher", shell.focusedScreen(), -1); }
        function close(): void { Popups.close(); }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property string screenName: modelData.name
            readonly property bool open: Popups.openId !== "" && Popups.screenName === screenName

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "kurtz-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: open ? null : emptyMask
            Region { id: emptyMask; width: 0; height: 0 }

            FocusScope {
                anchors.fill: parent
                focus: win.open
                Keys.onEscapePressed: Popups.close()

                Rectangle {
                    anchors.fill: parent
                    color: Theme.shadowColor
                    opacity: win.open ? Math.min(0.85, Theme.c.popupDim * 2.3) : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                    MouseArea {
                        anchors.fill: parent
                        enabled: win.open
                        onClicked: Popups.close()
                    }
                }

                PopupCard {
                    screenName: win.screenName
                    screenWidth: win.width
                    screenHeight: win.height
                    focus: shown
                    popupId: Config.s.launcherStyle === "orbit" ? "launcher-list" : "launcher"
                    cardWidth: 600
                    seed: 27
                    centered: true
                    content: Component { Launcher {} }
                }

                OrbitLauncher {
                    anchors.fill: parent
                    screenName: win.screenName
                }
            }
        }
    }
}
