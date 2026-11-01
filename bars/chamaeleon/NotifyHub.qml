pragma Singleton
import QtQuick

// Notification log + unread count. The actual NotificationServer lives in
// shell.qml (needs to own app lifetime) and calls into this singleton --
// same split as bars/claude/NotifyHub.qml. No toast here (out of scope for
// Stage 3, which only calls for the flyout itself); unread count on the
// bar trigger is the only "something arrived" signal for now.
QtObject {
    id: root

    property var log: [] // [{id, app, title, body, stamp}]
    property int unread: 0
    property var _live: ({})

    function receive(entry, liveHandle) {
        root._live[entry.id] = liveHandle;
        root.log = [entry, ...root.log];
        root.unread += 1;
    }

    function dismiss(id) {
        if (root._live[id]) {
            root._live[id].dismiss();
            delete root._live[id];
        }
        root.log = root.log.filter(n => n.id !== id);
    }

    function forget(id) {
        delete root._live[id];
        root.log = root.log.filter(n => n.id !== id);
    }

    function clearAll() {
        for (const id of root.log.map(n => n.id)) {
            if (root._live[id])
                root._live[id].dismiss();
        }
        root._live = {};
        root.log = [];
    }

    function markSeen() { root.unread = 0; }
}
