pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango compositor state via `mmsg watch all-monitors` (one JSON line per
// change). Same IPC convention as the sibling bars in quickdots.
Singleton {
    id: root

    property var monitors: []

    function monitor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }
    function tags(screenName) {
        const m = monitor(screenName);
        return m ? (m.tags || []) : [];
    }
    function title(screenName) {
        const m = monitor(screenName);
        return m && m.active_client ? (m.active_client.title || "") : "";
    }
    function appId(screenName) {
        const m = monitor(screenName);
        return m && m.active_client ? (m.active_client.appid || "") : "";
    }
    function layout(screenName) {
        const m = monitor(screenName);
        return m ? (m.layout_symbol || "") : "";
    }
    function view(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }
    function cycle(screenName, dir) {
        const t = tags(screenName);
        if (t.length === 0)
            return;
        const cur = t.findIndex(x => x.is_active);
        const next = ((cur < 0 ? 0 : cur) + dir + t.length) % t.length;
        view(screenName, t[next].index);
    }

    Process {
        id: proc
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
        onExited: restart.start()
    }
    Timer {
        id: restart
        interval: 1500
        onTriggered: proc.running = true
    }
}
