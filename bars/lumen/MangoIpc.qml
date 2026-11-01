pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Alle mmsg (mango IPC) Zugriffe leben hier -- uebernommen aus
// bars/simple/MangoIpc.qml (gleiche mmsg-Kommandos):
//   mmsg get/watch all-monitors
//   mmsg get/watch focusing-client
//   mmsg dispatch viewcrossmon,<index>,<monitor>
// `watch` liefert pro Zeile ein JSON-Objekt derselben Form wie das
// passende `get`, sobald sich der zugehoerige Zustand aendert.
// Root-Singleton aus demselben Grund wie Colors.qml.
QtObject {
    id: root

    property var monitors: []
    property string focusedTitle: ""
    property string focusedAppId: ""

    function monitorFor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }
    readonly property string focusedMonitorName: {
        const m = root.monitors.find(m => m.active);
        return m ? m.name : "";
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

    // -- all-monitors Stream, mit Auto-Restart falls mmsg stirbt --

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

    // -- focusing-client Stream, mit Auto-Restart --

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
