pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Liest mangos Zustand als Zeilenstrom aus `mmsg watch all-monitors`
// (eine JSON-Zeile pro Aenderung) und startet den Strom neu, falls er endet.
Singleton {
    id: root

    property var monitors: []

    readonly property string focusedName: {
        for (const m of monitors)
            if (m.active)
                return m.name;
        return "";
    }

    function monitor(name) {
        for (const m of monitors)
            if (m.name === name)
                return m;
        return null;
    }
    function tags(name) {
        const m = monitor(name);
        return m && m.tags ? m.tags : [];
    }
    function activeTags(name) {
        const m = monitor(name);
        return m && m.active_tags ? m.active_tags : [];
    }
    function title(name) {
        const m = monitor(name);
        return m && m.active_client ? (m.active_client.title || "") : "";
    }
    function view(name, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + name]);
    }

    property Process watcher: Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.monitors)
                        root.monitors = d.monitors;
                } catch (e) {}
            }
        }
        onExited: root.revive.restart()
    }
    property Timer revive: Timer {
        interval: 1500
        onTriggered: {
            root.watcher.running = false;
            root.watcher.running = true;
        }
    }
}
