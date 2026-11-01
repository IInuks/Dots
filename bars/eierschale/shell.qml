//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

// eierschale -- eine Überraschungsei-Shell für mango.
// Eine Leiste pro Bildschirm plus eine Overlay-Ebene pro Bildschirm, die
// alle Menüs, die Session-Ansicht und das OSD trägt. Farben kommen live aus
// dem aktuellen Wallpaper (Wall.qml -> Theme.qml). Tour: README.md.
ShellRoot {
    id: shell

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
    Variants {
        model: Quickshell.screens
        delegate: Overlay {}
    }
    Osd {}

    //   qs -p <diese Shell> ipc call panel toggle <launcher|control|calendar|system|egg|session|studio>
    IpcHandler {
        target: "panel"
        function toggle(id: string): void { Ui.toggle(id, Mango.focusedMonitor, -1); }
        function open(id: string): void { Ui.open(id, Mango.focusedMonitor, -1); }
        function close(): void { Ui.close(); }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggle("launcher", Mango.focusedMonitor, -1); }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Ui.toggle("session", Mango.focusedMonitor, -1); }
    }
    IpcHandler {
        target: "egg"
        function open(): void { Ui.open("egg", Mango.focusedMonitor, -1); }
        function toggle(): void { Ui.toggle("egg", Mango.focusedMonitor, -1); }
        // Menü öffnen und sofort ein neues Ei aufbrechen
        function crack(): void { Ui.open("egg", Mango.focusedMonitor, -1); Ui.crackRequested(); }
    }
    IpcHandler {
        target: "theme"
        // Wallpaper neu einlesen (z. B. aus einem Wallpaper-Skript heraus)
        function refresh(): void { Wall.refresh(); }
        function mode(m: string): void { Settings.data.themeMode = m; }
    }
    IpcHandler {
        target: "debug"
        function shot(name: string, path: string): string { return Shots.shot(name, path); }
        function toy(id: string): void { Ui.open("egg", Mango.focusedMonitor, -1); Ui.toyRequested(id); }
    }
}
