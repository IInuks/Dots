//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

// Polarlicht – eine Shell, deren Farben dem Wallpaper folgen.
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Overlay { screen: Quickshell.screens[0] }
    Toast { screen: Quickshell.screens[0] }

    // qs -p ~/quickdots/bars/polarlicht ipc call polarlicht toggle launcher
    IpcHandler {
        target: "polarlicht"
        function toggle(menu: string): void { Hub.toggle(menu) }
        function close(): void { Hub.close() }
        function wallpaper(path: string): void { Hub.setWallpaper(path) }
        function mode(m: string): void { Theme.cfg.mode = m }
    }
}
