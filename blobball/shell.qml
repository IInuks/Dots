import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    BlobWindow {}

    // Kein eigenes Menue mehr: die Einstellungen liegen als Tab "Blob" im
    // quickdots-Menue (menu/steps/BlobStep.qml), das blob.json schreibt --
    // Settings.qml laedt die Datei bei jeder Aenderung live nach. Das Menue
    // meldet hier nur, wann es offen ist, damit der Blob solange ausblendet.
    IpcHandler {
        target: "menu"
        function opened(): void { Settings.menuOpen = true; }
        function closed(): void { Settings.menuOpen = false; }
    }

    // Ziel fuer `qs -p <dir> ipc call notify show "<text>"` -- laesst den
    // Blob eine Nachricht anzeigen (siehe Message.qml zur Begruendung, warum
    // das ueber IPC statt ueber einen echten Notification-Server laeuft).
    IpcHandler {
        target: "notify"
        function show(text: string): void { Message.show(text); }
        function clear(): void { Message.clear(); }
    }

    // Ziel fuer `qs -p <dir> ipc call messages <fn>` -- oeffnet/schliesst die
    // Nachrichten-Flaeche ohne den Blob per Klick in der Ecke treffen zu
    // muessen (siehe BlobWindow.qml, atIdleCorner/messagesPanel). Kein
    // eigenes Fenster mehr -- der Blob verformt sich direkt in BlobWindow.qml.
    IpcHandler {
        target: "messages"
        function open(): void { Message.markAllRead(); Settings.messagesOpen = true; }
        function close(): void { Settings.messagesOpen = false; }
        function toggle(): void {
            if (Settings.messagesOpen) { Settings.messagesOpen = false; }
            else { Message.markAllRead(); Settings.messagesOpen = true; }
        }
    }
}
