pragma Singleton
import QtQuick

// Notification history + unread count + the one card currently showing as
// a toast. The actual NotificationServer lives in shell.qml (needs to own
// app lifetime) and calls into this singleton.
QtObject {
    id: root

    property var log: [] // [{id, app, icon, title, body, stamp}]
    property int unread: 0
    property var toast: null
    property var _live: ({})

    function receive(entry, liveHandle) {
        root._live[entry.id] = liveHandle;
        root.log = [entry, ...root.log];
        root.unread += 1;
        if (!Config.dnd)
            root.toast = entry;
    }

    function clearToast(id) {
        if (root.toast && root.toast.id === id)
            root.toast = null;
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
