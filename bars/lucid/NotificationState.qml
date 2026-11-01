pragma Singleton
import QtQuick

// Notification history + unread count + DND. The actual NotificationServer
// lives in shell.qml (needs to own app lifetime, and Quickshell.Services.
// Notifications allows exactly one server per DBus name) and calls into
// this singleton -- same split already proven in bars/claude, bars/
// chamaeleon, bars/ksp and bars/floating's NotifyHub/NotificationState.
// Unlike those, incoming toasts are shown via the existing ToastState
// singleton (see its own header comment) instead of a second toast
// mechanism -- this bar already had one from Stage 2's Reminders.
QtObject {
    id: root

    property var log: [] // [{id, app, title, body, actions, stamp}]
    property int unread: 0
    property var _live: ({}) // id -> real Notification object, for real dismiss()

    function receive(entry, liveNotif) {
        root._live[entry.id] = liveNotif;
        root.log = [entry, ...root.log];
        root.unread += 1;
        if (!Config.dnd)
            ToastState.show(entry.app || entry.title || "Notification", entry.title && entry.body ? entry.title + " — " + entry.body : (entry.title || entry.body));
    }

    // Removes our copy without calling dismiss() again -- used when the
    // sender itself already closed/expired the notification.
    function forget(id) {
        delete root._live[id];
        root.log = root.log.filter(n => n.id !== id);
    }

    function dismiss(id) {
        if (root._live[id]) {
            root._live[id].dismiss();
            delete root._live[id];
        }
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
