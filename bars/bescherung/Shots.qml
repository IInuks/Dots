pragma Singleton
import QtQuick
import Quickshell

// Debug: benannte Items als PNG speichern
//   qs -p <bar> ipc call bescherung shot <name> <datei.png>
Singleton {
    property var items: ({})
    function register(name, item) {
        items[name] = item;
    }
    function shot(name, path) {
        const it = items[name];
        if (!it)
            return "unbekannt: " + name + " (da: " + Object.keys(items).join(", ") + ")";
        it.grabToImage(r => r.saveToFile(path));
        return "ok";
    }
}
