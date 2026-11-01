pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango (mmsg) IPC access, trimmed to what this bar's WorkspacePips + Tags
// module + power actions need. Verified subcommands/JSON shapes copied
// from bars/lucid/MangoService.qml (see that file's header comment for the
// full investigation: `mmsg --help`, a live two-window session, and the
// mangowc wiki, cross-checked against each other) -- re-derived from
// scratch here since Quickshell can't import QML from outside this
// directory (feedback_quickshell_module_outside_config_folder), so a fresh
// copy, not a symlink.
QtObject {
    id: root

    property var monitors: []
    property string focusedTitle: ""
    property int focusedClientId: -1

    function monitorFor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }

    // Array of {index, is_active, is_urgent, layout, client_count}, 1-based.
    function tagsFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.tags || []) : [];
    }

    function activeTagIndicesFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.active_tags || []) : [];
    }

    function viewTag(screenName, tagIndex) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + tagIndex + "," + screenName]);
    }

    function scrollTag(screenName, dir) {
        const tags = root.tagsFor(screenName);
        if (tags.length === 0) return;
        const active = root.activeTagIndicesFor(screenName);
        const current = active.length > 0 ? active[0] : tags[0].index;
        const idx = tags.findIndex(t => t.index === current);
        const nextIdx = (idx + dir + tags.length) % tags.length;
        root.viewTag(screenName, tags[nextIdx].index);
    }

    // -- power actions (PowerMenu panel) --
    function lock() { Quickshell.execDetached(["swaylock"]); }
    function logout() { Quickshell.execDetached(["mmsg", "dispatch", "quit"]); }
    function reboot() { Quickshell.execDetached(["systemctl", "reboot"]); }
    function shutdown() { Quickshell.execDetached(["systemctl", "poweroff"]); }

    // -- all-monitors stream, auto-restart if mango/mmsg dies --

    property Process _monitorsProc: Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser { onRead: line => root._onMonitorsLine(line) }
        onExited: _monitorsRestart.start()
    }
    property Timer _monitorsRestart: Timer {
        interval: 1000
        onTriggered: { _monitorsProc.running = false; _monitorsProc.running = true; }
    }
    function _onMonitorsLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        if (data.monitors) root.monitors = data.monitors;
    }

    // -- focusing-client stream (bar's active-title module) --

    property Process _focusProc: Process {
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser { onRead: line => root._onFocusLine(line) }
        onExited: _focusRestart.start()
    }
    property Timer _focusRestart: Timer {
        interval: 1000
        onTriggered: { _focusProc.running = false; _focusProc.running = true; }
    }
    function _onFocusLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        if (data.error) { root.focusedTitle = ""; root.focusedClientId = -1; return; }
        root.focusedTitle = data.title || "";
        root.focusedClientId = (data.id !== undefined && data.id !== null) ? data.id : -1;
    }
}
