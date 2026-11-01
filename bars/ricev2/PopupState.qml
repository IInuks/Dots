pragma Singleton
import QtQuick

// Toast queue for the bar's own notification-popup daemon (menus prompt
// section 5). The NotificationServer itself lives in Bar/notifications/
// PopupHost.qml -- it needs a stable app-lifetime owner, same reasoning
// as bars/claude/NotifyHub.qml's split from its shell.qml -- this
// singleton just holds the ordered queue so the popup stack (and nothing
// else needs to today) has one shared source of truth. Only the first
// Style.popupMaxVisible entries are ever rendered (spec: "max. 4
// sichtbar"); the rest sit here until a slot frees up by naturally
// falling out of the visible slice once an earlier one is removed.
QtObject {
    id: root

    property var queue: [] // [{id, notif, appName, summary, body, actions, timeoutMs}], oldest first

    function push(entry) {
        root.queue = [...root.queue, entry];
    }

    function remove(id) {
        root.queue = root.queue.filter(e => e.id !== id);
    }
}
