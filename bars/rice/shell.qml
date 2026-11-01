import QtQuick
import Quickshell
import Quickshell.Io
import "Bar"
import "Panels"

// Root. One Bar per connected screen; the three panels (ControlCenter,
// WallpaperSwitcher, PowerMenu) are single global instances anchored to
// the primary screen only (PanelSheet.qml) -- a known Stage 1
// simplification for multi-monitor setups, see README "Bekannte Lücken".
//
// IPC targets match the adapters/*.json convention every sibling bar in
// quickdots/menu already uses (`qs -p <dir> ipc call <target> toggle`).
ShellRoot {
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { PanelState.toggle("controlcenter"); }
        function open(): void { PanelState.open("controlcenter"); }
        function close(): void { PanelState.close(); }
    }
    IpcHandler {
        target: "wallpapers"
        function toggle(): void { PanelState.toggle("wallpapers"); }
        function open(): void { PanelState.open("wallpapers"); }
        function close(): void { PanelState.close(); }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { PanelState.toggle("power"); }
        function open(): void { PanelState.open("power"); }
        function close(): void { PanelState.close(); }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    ControlCenter {}
    WallpaperSwitcher {}
    PowerMenu {}
}
