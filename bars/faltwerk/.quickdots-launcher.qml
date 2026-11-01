//@ pragma ShellId 6ff7d1ac79bd70739c918baf1e751fd2
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "core"
import "fold"
import "launcher"

// Launcher-only host for bars/faltwerk (see the menu README, "Launcher
// mischen"): the folded sheet (launcher/Launcher.qml) plus the paper plane,
// on a per-screen overlay -- the same parts faltwerk's menus/Overlay.qml
// uses, without the bar and the other menus.
ShellRoot {
    IpcHandler {
        target: "launcher"
        function toggle(): void { Falt.toggle("launcher", Mango.focusedMonitor, -1); }
        function open(): void { Falt.open("launcher", Mango.focusedMonitor, -1); }
        function close(): void { Falt.close(); }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool active: Falt.isOpen("launcher", modelData.name)

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "faltwerk-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: active ? null : emptyMask
            Region { id: emptyMask; width: 0; height: 0 }

            FocusScope {
                anchors.fill: parent
                focus: win.active
                Keys.onEscapePressed: Falt.close()

                Rectangle {
                    anchors.fill: parent
                    color: Paper.dark ? "#000000" : Paper.ink
                    opacity: sheet.progress * (Paper.dark ? 0.5 : 0.35)
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: win.active
                    onClicked: Falt.close()
                }
                Launcher {
                    id: sheet
                    screenName: win.modelData.name
                    areaWidth: win.width
                    areaHeight: win.height
                }
                PaperPlane {
                    screenName: win.modelData.name
                    anchors.fill: parent
                }
            }
        }
    }
}
