pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "pool.js" as Pool

// Das Tagesgeschenk: jeden Tag liegt ein neues, verpacktes Paeckchen in der
// Leiste. Welche Ueberraschung drinsteckt, haengt nur vom Datum ab. Ob es
// heute schon ausgepackt wurde und wie viele Tage gesammelt sind, wird
// unter ~/.local/state/quickshell/.../tagesgeschenk.json gespeichert.
Singleton {
    id: root

    property string today: _dateKey(new Date())
    property string openedOn: ""
    property int collected: 0

    readonly property bool openedToday: openedOn === today
    readonly property real dayHash: _hash(today)
    readonly property var current: {
        const p = Pool.pool[dayHash % Pool.pool.length];
        const k = Pool.kinds[p[0]];
        return { kind: p[0], text: p[1], label: k.label, icon: k.icon };
    }
    // Das Paeckchen hat jeden Tag ein anderes Papier.
    readonly property int paper: dayHash % Theme.papers.length

    function _dateKey(d) {
        return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
    }
    function _hash(s) {
        let h = 2166136261;
        for (let i = 0; i < s.length; i++) {
            h ^= s.charCodeAt(i);
            h = Math.imul(h, 16777619);
        }
        return h >>> 0;
    }

    function open() {
        if (openedToday)
            return;
        openedOn = today;
        collected += 1;
        store.setText(JSON.stringify({ openedOn: openedOn, collected: collected }));
    }

    // Fuer Tests: Paeckchen wieder zukleben
    function reset() {
        if (!openedToday)
            return;
        openedOn = "";
        collected = Math.max(0, collected - 1);
        store.setText(JSON.stringify({ openedOn: openedOn, collected: collected }));
    }

    property FileView store: FileView {
        path: Quickshell.statePath("tagesgeschenk.json")
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.openedOn = d.openedOn || "";
                root.collected = d.collected || 0;
            } catch (e) {}
        }
    }

    // Um Mitternacht liegt ein neues Paeckchen da.
    property Timer midnight: Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.today = root._dateKey(new Date())
    }
}
