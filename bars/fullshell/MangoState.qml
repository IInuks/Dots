pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live mango compositor state via `mmsg watch` -- own copy per this repo's
// convention of never importing another bar's singletons.
QtObject {
    id: root

    property var tags: [] // [{index, is_active, is_urgent, client_count}, ...]
    property int activeTagIndex: 1

    function viewTag(index) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + index + ",0"]);
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
