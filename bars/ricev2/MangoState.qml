pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live mango tag/workspace state via `mmsg watch all-monitors`, feeding
// Bar/lyrics/WorkspacePips.qml (the middle island's idle-state content).
// Same subscription shape as bars/quickbar/MangoState.qml, already
// verified working on this system -- reused rather than re-derived.
// Root singleton for the same same-dir/pure-".." import reason as every
// other ricev2 singleton (memory: feedback_quickshell_singleton_cross_dir_import).
QtObject {
    id: root

    property var tags: []          // [{index, is_active, is_urgent, client_count}, ...]
    property int activeTagIndex: 1

    function viewTag(index) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + index + ",0"]);
    }

    function scrollTag(delta) {
        if (root.tags.length === 0)
            return;
        const idx = root.tags.findIndex(t => t.index === root.activeTagIndex);
        const n = root.tags.length;
        let next = ((idx < 0 ? 0 : idx) + delta) % n;
        if (next < 0)
            next += n;
        root.viewTag(root.tags[next].index);
    }

    property Process _monitorsProc: Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onMonitorsLine(line)
        }
    }

    function _onMonitorsLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        const mons = data.monitors || [];
        if (!mons.length) return;
        const m = mons.find(x => x.active) || mons[0];
        root.tags = m.tags || [];
        const activeTag = root.tags.find(t => t.is_active);
        if (activeTag) root.activeTagIndex = activeTag.index;
    }
}
