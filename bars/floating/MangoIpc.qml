pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// All mmsg (mango IPC) access lives here so a future mango version bump
// with a changed output format only needs a fix in one place. Verified
// against mango 0.16.1 / mmsg's real CLI (not the `-w -t` style flags an
// older mango version used) -- see `mmsg --help`:
//   mmsg get all-monitors / mmsg watch all-monitors
//   mmsg get focusing-client / mmsg watch focusing-client
//   mmsg dispatch view,<mask>,<synctag>
//   mmsg dispatch viewcrossmon,<mask>,<monitor>
// `watch` streams one JSON object per line, same shape as the matching
// `get`, whenever the underlying state changes.
QtObject {
    id: root

    // monitors: [{name, tags:[{index,is_active,is_urgent,client_count}],
    //             active_tags:[...], active_client:{title,appid}|null}, ...]
    property var monitors: []
    // focusing-client stream: title/appid of whatever currently has focus,
    // regardless of which monitor it's on.
    property string focusedTitle: ""
    property string focusedAppId: ""

    function monitorFor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }
    function tagsFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.tags || []) : [];
    }
    function activeTagsFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.active_tags || []) : [];
    }

    // Explicit monitor targeting (viewcrossmon) instead of plain `view`,
    // which only ever affects the currently focused monitor -- a click on
    // a tag square on a non-focused screen must still work.
    function viewTag(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }

    // -- all-monitors stream, with auto-restart if mmsg dies --

    property Process _monitorsProc: Process {
        id: monitorsProc
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onMonitorsLine(line)
        }
        onExited: _monitorsRestart.start()
    }
    property Timer _monitorsRestart: Timer {
        interval: 1000
        onTriggered: { monitorsProc.running = false; monitorsProc.running = true; }
    }

    function _onMonitorsLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        if (data.monitors) root.monitors = data.monitors;
    }

    // -- focusing-client stream, with auto-restart --

    property Process _focusProc: Process {
        id: focusProc
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onFocusLine(line)
        }
        onExited: _focusRestart.start()
    }
    property Timer _focusRestart: Timer {
        interval: 1000
        onTriggered: { focusProc.running = false; focusProc.running = true; }
    }

    function _onFocusLine(line) {
        let data;
        try { data = JSON.parse(line); } catch (e) { return; }
        if (data.error) return; // e.g. no client focused
        root.focusedTitle = data.title || "";
        root.focusedAppId = data.appid || "";
    }
}
