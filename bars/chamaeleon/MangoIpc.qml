pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango IPC (mmsg) access, following the same convention every sibling
// bar duplicates independently (see e.g. bars/simple/MangoIpc.qml):
//   mmsg watch all-monitors        -> tags per monitor
//   mmsg watch focusing-client     -> currently focused window
//   mmsg dispatch viewcrossmon,<index>,<monitor>
// Root singleton for the same reason as Theme/Metrics: a name that isn't
// a Quickshell/QtQuick builtin.
QtObject {
    id: root

    property var monitors: []
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

    function viewTag(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }

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
        onTriggered: {
            monitorsProc.running = false;
            monitorsProc.running = true;
        }
    }

    function _onMonitorsLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.monitors)
            root.monitors = data.monitors;
    }

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
        onTriggered: {
            focusProc.running = false;
            focusProc.running = true;
        }
    }

    function _onFocusLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.error)
            return;
        root.focusedTitle = data.title || "";
        root.focusedAppId = data.appid || "";
    }
}
