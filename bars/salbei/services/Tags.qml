pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// MangoWM tags via `mmsg watch all-tags` (one JSON object per change).
// Quickshell has no dwl-ipc-v2 module, so mmsg is the cleanest event source.
Singleton {
    id: root

    property bool available: true
    // { "DP-4": [ {index, active, urgent, clients}, ... ] }
    property var monitors: ({})

    function tagsFor(name) {
        const list = monitors[name] ?? Object.values(monitors)[0] ?? [];
        // show at least 3 tags, more when a higher one is active or occupied
        let last = 3;
        for (const t of list)
            if (t.active || t.clients > 0 || t.urgent) last = Math.max(last, t.index);
        return list.filter(t => t.index <= last);
    }

    function view(index) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + index + ",0"]);
    }
    function viewRelative(monitor, step) {
        const list = tagsFor(monitor);
        const cur = list.find(t => t.active);
        if (!cur) return;
        const next = cur.index + step;
        if (next >= 1 && next <= 9) view(next);
    }

    Process {
        id: watcher
        command: ["mmsg", "watch", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let data;
                try { data = JSON.parse(line); } catch (e) { return; }
                const out = {};
                for (const m of data.all_tags ?? [])
                    out[m.monitor] = m.tags.map(t => ({
                        index: t.index,
                        active: t.is_active,
                        urgent: t.is_urgent,
                        clients: t.client_count
                    }));
                root.monitors = out;
                root.available = true;
            }
        }
        onExited: code => {
            if (code === 127) root.available = false;
            restart.start();
        }
    }

    // mmsg dies when the compositor restarts or isn't ready yet: retry slowly.
    Timer {
        id: restart
        interval: 3000
        onTriggered: watcher.running = true
    }
}
