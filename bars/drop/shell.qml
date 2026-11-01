//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

// drop -- eine Wassertropfen-Shell für mango.
// Eine Leiste pro Bildschirm (Wasserfilm mit hängenden Perlen) plus eine
// Overlay-Ebene pro Bildschirm, aus der die Menüs als Tropfen fallen.
// Farben kommen live aus dem Wallpaper (Wall.qml -> Theme.qml). Tour: README.md.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
    Variants {
        model: Quickshell.screens
        delegate: Overlay {}
    }
    Osd {}
    Variants {
        model: Quickshell.screens
        delegate: Arranger {}
    }

    //   qs -p <diese Shell> ipc call panel toggle <launcher|control|calendar|system|studio|session>
    IpcHandler {
        target: "panel"
        function toggle(id: string): void { Ui.toggle(id, Mango.focusedMonitor, -1, 0); }
        function open(id: string): void { Ui.open(id, Mango.focusedMonitor, -1, 0); }
        function close(): void { Ui.close(); }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggle("launcher", Mango.focusedMonitor, -1, 0); }
        function open(): void { Ui.open("launcher", Mango.focusedMonitor, -1, 0); }
        function close(): void { Ui.close(); }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Ui.toggle("session", Mango.focusedMonitor, -1, 0); }
    }
    IpcHandler {
        target: "theme"
        function refresh(): void { Wall.refresh(); }
        function mode(m: string): void { Settings.data.themeMode = m; }
    }
    //   qs -p <diese Shell> ipc call layout <edit|done|save|revert|remove>
    IpcHandler {
        target: "layout"
        function edit(): void { Arrange.begin(); }
        function done(): void { Arrange.finish(); }
        function save(): void { Arrange.save(); }
        function revert(): void { Arrange.revert(); }
        function remove(): void { Arrange.remove(); }
        function dump(): string { return JSON.stringify(Arrange.groups); }
    }
    IpcHandler {
        target: "debug"
        function shot(name: string, path: string): string { return Shots.shot(name, path); }
        // Menü so öffnen, als käme es aus einer Perle bei x mit Breite w
        function pop(id: string, x: real, w: real): void { Ui.open(id, Mango.focusedMonitor, x, w); }
        // Perle wie mit der Maus ziehen: linke Kante nach x loslassen
        function move(key: string, x: real): string {
            const b = Shots.items["barwin@" + Mango.focusedMonitor];
            if (!b || !b.beadOf(key)) return "unbekannt";
            b.grab(key, 0); b.drag(x); b.drop();
            return JSON.stringify(Arrange.groups);
        }
    }
}
