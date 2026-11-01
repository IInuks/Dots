pragma Singleton
import QtQuick

// Shared with ClockModule (unread dot) and the Notifications tab (list).
// The NotificationServer instance itself lives in shell.qml and pushes into
// this singleton, since Quickshell.Services.Notifications requires exactly
// one server per DBus name and shell.qml already owns app lifetime.
QtObject {
    id: root

    property var items: [] // [{id, appName, appIcon, summary, body, time, urgency}]
    property int unreadCount: 0
    property var _live: ({}) // id -> real Notification object, for proper dismiss()

    function push(entry, liveNotif) {
        root._live[entry.id] = liveNotif;
        root.items = [entry, ...root.items];
        root.unreadCount += 1;
    }
    function dismiss(id) {
        if (root._live[id]) { root._live[id].dismiss(); delete root._live[id]; }
        root.items = root.items.filter(n => n.id !== id);
    }
    // Removes our copy without calling dismiss() again -- used when the
    // sender itself already closed/expired the notification.
    function removeOnly(id) {
        delete root._live[id];
        root.items = root.items.filter(n => n.id !== id);
    }
    function clearAll() {
        for (const id of root.items.map(n => n.id)) {
            if (root._live[id]) root._live[id].dismiss();
        }
        root._live = {};
        root.items = [];
    }
    function markRead() {
        root.unreadCount = 0;
    }
}
