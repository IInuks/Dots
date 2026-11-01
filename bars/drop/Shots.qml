pragma Singleton
import QtQuick
import Quickshell

// Debug: benannte Elemente als PNG speichern (es gibt kein grim hier)
//   qs -p <shell> ipc call debug shot <name> <datei.png>
Singleton {
    property var items: ({})
    function register(name, item) { items[name] = item; }
    function shot(name, path) {
        const it = items[name];
        if (!it) return "unbekannt: " + name + " (da: " + Object.keys(items).join(", ") + ")";
        it.grabToImage(r => r.saveToFile(path));
        return "ok";
    }
}
