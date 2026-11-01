pragma Singleton
import QtQuick
import Quickshell
import "../"

// Notification history + currently visible toasts. The NotificationServer
// itself lives in shell.qml (it must own the shell's lifetime) and calls
// receive() here.
Singleton {
    id: root

    // [{id, app, summary, body, urgency, image, icon, time, actions:[{id,text}]}]
    property var history: []
    property var toasts: []       // subset of ids currently shown as toasts
    property int unread: 0
    property var _live: ({})

    readonly property bool dnd: Config.s.dnd

    function receive(n) {
        const entry = {
            id: n.id,
            app: n.appName || "System",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency, // 0 low, 1 normal, 2 critical
            image: n.image || "",
            icon: n.appIcon || "",
            time: new Date(),
            actions: (n.actions || []).map(a => ({ id: a.identifier, text: a.text }))
        };
        root._live[n.id] = n;
        root.history = [entry, ...root.history.filter(e => e.id !== n.id)].slice(0, 80);
        root.unread += 1;
        if (!root.dnd || n.urgency === 2)
            root.toasts = [n.id, ...root.toasts.filter(i => i !== n.id)].slice(0, 4);
    }

    function entry(id) {
        return root.history.find(e => e.id === id) || null;
    }

    function hideToast(id) {
        root.toasts = root.toasts.filter(i => i !== id);
    }

    function invoke(id, actionId) {
        const n = root._live[id];
        if (n) {
            const a = (n.actions || []).find(x => x.identifier === actionId);
            if (a)
                a.invoke();
        }
        root.dismiss(id);
    }

    function dismiss(id) {
        const n = root._live[id];
        if (n)
            n.dismiss();
        root.forget(id);
    }

    function forget(id) {
        delete root._live[id];
        root.history = root.history.filter(e => e.id !== id);
        root.hideToast(id);
    }

    function clearAll() {
        for (const e of root.history) {
            const n = root._live[e.id];
            if (n)
                n.dismiss();
        }
        root._live = {};
        root.history = [];
        root.toasts = [];
        root.unread = 0;
    }

    function markSeen() {
        root.unread = 0;
    }

    function ago(date) {
        const s = Math.floor((Date.now() - date.getTime()) / 1000);
        if (s < 60) return "jetzt";
        if (s < 3600) return Math.floor(s / 60) + " min";
        if (s < 86400) return Math.floor(s / 3600) + " h";
        return Qt.formatDate(date, "dd.MM.");
    }
}
