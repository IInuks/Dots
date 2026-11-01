pragma Singleton
import QtQuick
import Quickshell

// Debug helper: named items can be grabbed to PNG over IPC
//   qs -p <kurtz> ipc call debug shot <name> <file.png>
// (Used while developing to check the look without a screenshot tool.)
Singleton {
    id: root
    property var items: ({})

    function register(name, item) {
        root.items[name] = item;
    }

    function shot(name, path) {
        const it = root.items[name];
        if (!it)
            return "unknown item: " + name + " (have: " + Object.keys(root.items).join(", ") + ")";
        it.grabToImage(r => r.saveToFile(path));
        return "ok";
    }
}
