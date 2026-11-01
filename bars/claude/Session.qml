pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Talks to mango's own IPC daemon (`mmsg`) for tag/workspace state -- the
// only way to get this under mango, which has no Hyprland-style
// compositor module in Quickshell.
QtObject {
    id: root

    property var monitors: []

    function _monitor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }

    function tagsOn(screenName) {
        const m = root._monitor(screenName);
        return m ? (m.tags || []) : [];
    }

    function activeTagOn(screenName) {
        const tags = root.tagsOn(screenName);
        const active = tags.find(t => t.is_active);
        return active ? active.index : 1;
    }

    function goToTag(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }

    property Process _watcher: Process {
        id: watcher
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let parsed;
                try {
                    parsed = JSON.parse(line);
                } catch (e) {
                    return;
                }
                if (parsed.monitors)
                    root.monitors = parsed.monitors;
            }
        }
        onExited: restartTimer.restart()
    }

    property Timer _restartTimer: Timer {
        id: restartTimer
        interval: 1200
        onTriggered: {
            watcher.running = false;
            watcher.running = true;
        }
    }
}
