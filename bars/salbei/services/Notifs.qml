pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../"

// org.freedesktop.Notifications server. Keeps a history (plain copies) and the list
// of currently visible toasts. DND (Ui.dnd) only suppresses toasts, not history.
Singleton {
    id: root

    property var history: []              // newest first
    property var toasts: []
    property int _seq: 0

    function _copy(n) {
        return {
            key: ++_seq,
            id: n.id,
            appName: n.appName || "Notification",
            appIcon: n.appIcon || "",
            image: n.image || "",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency,
            timeout: n.expireTimeout > 0 ? n.expireTimeout : Theme.toastTimeout,
            time: new Date(),
            ref: n
        };
    }

    function push(entry) {
        history = [entry].concat(history).slice(0, 100);
        if (!Ui.dnd || entry.urgency === NotificationUrgency.Critical)
            toasts = toasts.concat([entry]).slice(-5);
    }

    function dismissToast(key) {
        toasts = toasts.filter(t => t.key !== key);
    }
    function remove(key) {
        const e = history.find(h => h.key === key);
        if (e?.ref) try { e.ref.dismiss(); } catch (err) {}
        history = history.filter(h => h.key !== key);
        dismissToast(key);
    }
    function clear() {
        for (const e of history) if (e.ref) try { e.ref.dismiss(); } catch (err) {}
        history = [];
        toasts = [];
    }

    // for testing without a sender: `qs -p … ipc call notifications test`
    function test() {
        push({ key: ++_seq, id: -1, appName: "Shell", appIcon: "", image: "",
               summary: "Hello from the shell", body: "This is a test notification with a little body text.",
               urgency: NotificationUrgency.Normal, timeout: Theme.toastTimeout, time: new Date(), ref: null });
    }

    NotificationServer {
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: false
        keepOnReload: false
        onNotification: n => {
            n.tracked = true;
            root.push(root._copy(n));
        }
    }
}
