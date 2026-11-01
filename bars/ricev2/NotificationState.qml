pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backing store for the "NOTIFICATIONS" dropdown (menus prompt 1.6). This
// singleton originally only read the log; Stage 5's popup daemon
// (Bar/notifications/PopupHost.qml) now also calls record() below to
// append every incoming notification.
//
// Two files, exactly as spec'd: notifications.json is the live log (max
// 200 entries, newest first), notifications-dismissed.json is the set of
// ids a user has individually dismissed (kept separate so a daemon
// re-writing notifications.json doesn't resurrect something the user
// already closed).
QtObject {
    id: root

    readonly property string _dir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd"

    property var log: [] // [{ts, appName, summary, body, timeText}], newest first, dismissed already filtered out
    readonly property int count: root.log.length

    property var _dismissedIds: ({})

    // Called by Bar/notifications/PopupHost.qml's NotificationServer for
    // every incoming notification (menus prompt section 5, last bullet:
    // "wird zusätzlich in notifications.json geschrieben ... damit das
    // Benachrichtigungszentrum der Bar sie anzeigen kann"). Newest first,
    // capped at 200 entries as spec'd.
    function record(entry) {
        const raw = _logFile.parsed || [];
        const next = [entry, ...raw].slice(0, 200);
        _logFile.parsed = next;
        _logFile.setText(JSON.stringify(next));
        root._recompute();
    }

    function _recompute() {
        const raw = _logFile.parsed || [];
        root.log = raw.filter(n => !root._dismissedIds[String(n.ts)]);
    }

    function dismiss(ts) {
        root._dismissedIds[String(ts)] = true;
        root._recompute();
        _dismissedFile.setText(JSON.stringify(Object.keys(root._dismissedIds)));
    }

    function clearAll() {
        for (const n of root.log)
            root._dismissedIds[String(n.ts)] = true;
        root._recompute();
        _dismissedFile.setText(JSON.stringify(Object.keys(root._dismissedIds)));
    }

    property FileView _logFile: FileView {
        id: logFile
        path: root._dir + "/notifications.json"
        printErrors: false
        watchChanges: true
        property var parsed: []
        onLoaded: {
            try {
                parsed = JSON.parse(text());
            } catch (e) {
                parsed = [];
            }
            root._recompute();
        }
        onLoadFailed: {
            parsed = [];
            root._recompute();
        }
        onFileChanged: reload()
    }

    property FileView _dismissedFile: FileView {
        id: dismissedFile
        path: root._dir + "/notifications-dismissed.json"
        printErrors: false
        onLoaded: {
            try {
                const ids = JSON.parse(text());
                const map = {};
                for (const id of ids)
                    map[id] = true;
                root._dismissedIds = map;
            } catch (e) {
                root._dismissedIds = {};
            }
            root._recompute();
        }
        onLoadFailed: {
            root._dismissedIds = {};
        }
    }

    // $XDG_RUNTIME_DIR/skwd doesn't exist until something creates it --
    // neither FileView.setText() nor a future daemon's writer should have
    // to guess whether that's already happened.
    property Process _mkdirProc: Process {
        command: ["mkdir", "-p", root._dir]
    }
    Component.onCompleted: _mkdirProc.running = true
}
