pragma Singleton
import QtQuick
import Quickshell

// App-Index fuer den Launcher. Leere Suche = "Oft gefaltet" (nach
// Store.usage) und danach alphabetisch. Mit Text: Praefix > Wortanfang >
// enthaelt > Beschreibung/Schlagworte > Buchstabenfolge.
Singleton {
    id: root

    // Desktop-Eintraege laden verzoegert nach -> bei jeder Aenderung neu
    property var all: []
    function rebuild() {
        all = DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name));
    }
    Component.onCompleted: rebuild()
    property Connections _watch: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.rebuild();
        }
    }

    function key(e) {
        return e.id || e.name;
    }

    function _subseq(q, s) {
        let i = 0;
        for (let c of s) {
            if (c === q[i])
                i++;
            if (i === q.length)
                return true;
        }
        return false;
    }

    function search(text) {
        const q = text.trim().toLowerCase();
        const usage = Store.usage;
        if (q === "") {
            return all.slice().sort((a, b) => (usage[key(b)] || 0) - (usage[key(a)] || 0));
        }
        const scored = [];
        for (const e of all) {
            const n = e.name.toLowerCase();
            let s = 0;
            if (n.startsWith(q))
                s = 100;
            else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
                s = 80;
            else if (n.includes(q))
                s = 60;
            else {
                const extra = [e.genericName || "", e.comment || "", (e.keywords || []).join(" "), e.id || ""].join(" ").toLowerCase();
                if (extra.includes(q))
                    s = 35;
                else if (q.length > 1 && _subseq(q, n))
                    s = 20;
            }
            if (s > 0)
                scored.push({
                    e: e,
                    s: s + Math.min(15, (usage[key(e)] || 0))
                });
        }
        scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return scored.map(x => x.e);
    }

    function launch(e) {
        Store.bump(key(e));
        e.execute();
    }
    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }
}
