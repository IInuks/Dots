pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live mango compositor state via `mmsg watch`, shared by the workspace
// strip and the window list so both read one subscription instead of two.
QtObject {
    id: root

    property var monitor: null
    property var tags: []          // [{index, is_active, is_urgent, client_count}, ...] length 9
    property int activeTagIndex: 1
    property var clients: []       // [{id, title, appid, tags, is_focused, ...}, ...]

    readonly property var clientsOnActiveTag: root.clients.filter(c => c.tags && c.tags.indexOf(root.activeTagIndex) !== -1)

    function viewTag(index) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + index + ",0"]);
    }
    function focusClient(id) {
        Quickshell.execDetached(["mmsg", "dispatch", "focusid", "client," + id]);
    }

    property Process _monitorsProc: Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onMonitorsLine(line)
        }
    }
    property Process _clientsProc: Process {
        command: ["mmsg", "watch", "all-clients"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onClientsLine(line)
        }
    }

    function _onMonitorsLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        const mons = data.monitors || [];
        if (!mons.length) return;
        const m = mons.find(x => x.active) || mons[0];
        root.monitor = m;
        root.tags = m.tags || [];
        const activeTag = root.tags.find(t => t.is_active);
        if (activeTag) root.activeTagIndex = activeTag.index;
    }

    function _onClientsLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        root.clients = data.clients || [];
    }
}
