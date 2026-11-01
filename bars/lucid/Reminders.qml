pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted reminder list for the Clock panel. Fires a ToastState toast
// once per reminder at its due time -- checked every 15s against
// Clock.now, not a per-reminder Timer (simplest way to survive the bar
// itself restarting: due-ness is recomputed from the persisted dueAt
// timestamp, not from a live countdown that a restart would reset).
QtObject {
    id: root

    property bool ready: false
    property var items: [] // {id, text, dueAt (ISO string), fired}

    function add(text, dueAt) {
        const item = {
            id: Date.now() + "-" + Math.floor(Math.random() * 10000),
            text: text,
            dueAt: dueAt.toISOString(),
            fired: false
        };
        root.items = root.items.concat([item]);
        _persist();
    }

    function remove(id) {
        root.items = root.items.filter(i => i.id !== id);
        _persist();
    }

    function _checkDue() {
        const now = Clock.now.getTime();
        let changed = false;
        const next = root.items.map(i => {
            if (!i.fired && new Date(i.dueAt).getTime() <= now) {
                ToastState.show("Reminder", i.text);
                changed = true;
                return Object.assign({}, i, { fired: true });
            }
            return i;
        });
        if (changed) {
            root.items = next;
            _persist();
        }
    }

    property Timer _dueCheck: Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root._checkDue()
    }
    Component.onCompleted: root._checkDue()

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.items = root.items;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.config/lucidbar/reminders.json"
        watchChanges: false
        atomicWrites: true
        adapter: JsonAdapter {
            property var items: []
        }
        onLoaded: {
            root.items = adapter.items;
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            root._persist();
        }
    }
}
