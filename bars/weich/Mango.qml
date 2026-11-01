pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Thin wrapper around mango's `mmsg` IPC. Verified against the running
// mango instance (`mmsg get all-monitors`): each monitor entry carries its
// own "tags" (workspaces) and "active_client" (currently focused window on
// that monitor), so a single watch stream covers both the workspace pills
// and the window-title readout.
QtObject {
    id: root

    property var monitors: []

    function _monitor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }
    function tagsFor(screenName) {
        const m = root._monitor(screenName);
        return m ? (m.tags || []).slice(0, 5) : [];
    }
    function activeTagIndex(screenName) {
        const m = root._monitor(screenName);
        return (m && m.active_tags && m.active_tags.length) ? m.active_tags[0] : 1;
    }
    function focusedTitle(screenName) {
        const m = root._monitor(screenName);
        return (m && m.active_client) ? m.active_client.title : "";
    }
    function selectTag(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }

    property Process _watch: Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onLine(line)
        }
        onExited: _restart.start()
    }
    property Timer _restart: Timer {
        interval: 1000
        onTriggered: { root._watch.running = false; root._watch.running = true; }
    }

    function _onLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        if (data.monitors) root.monitors = data.monitors;
    }
}
