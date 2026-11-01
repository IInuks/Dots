pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop-Einträge + Suche, die sich merkt, was du startest.
Singleton {
    id: root

    property var usage: ({})
    // früh anfassen, damit die Liste beim ersten Öffnen schon da ist
    Component.onCompleted: DesktopEntries.applications.values.length

    FileView {
        id: store
        path: Quickshell.statePath("drop-apps.json")
        printErrors: false
        onLoaded: { try { root.usage = JSON.parse(text()) || {}; } catch (e) { root.usage = {}; } }
    }

    function launch(entry) {
        const u = Object.assign({}, root.usage);
        const e = u[entry.id] || { n: 0, t: 0 };
        e.n += 1; e.t = Date.now();
        u[entry.id] = e;
        root.usage = u;
        store.setText(JSON.stringify(u));
        entry.execute();
    }

    function _score(e, q) {
        const name = (e.name || "").toLowerCase();
        let s = 0;
        if (name === q) s = 100;
        else if (name.startsWith(q)) s = 80;
        else if (name.split(/[\s-]/).some(w => w.startsWith(q))) s = 65;
        else if (name.includes(q)) s = 50;
        else if ((e.genericName || "").toLowerCase().includes(q)) s = 35;
        else if ((e.keywords || []).join(" ").toLowerCase().includes(q)) s = 20;
        else {
            // Buchstaben in Reihenfolge ("ffx" -> firefox)
            let i = 0;
            for (const ch of name) if (ch === q[i]) i++;
            if (i === q.length) s = 10;
        }
        if (s > 0) s += Math.min(15, ((root.usage[e.id] || {}).n || 0));
        return s;
    }

    function query(text) {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const q = (text || "").trim().toLowerCase();
        if (!q.length) {
            return all.slice().sort((a, b) => {
                const ua = root.usage[a.id] || { n: 0 }, ub = root.usage[b.id] || { n: 0 };
                if (ua.n !== ub.n) return ub.n - ua.n;
                return (a.name || "").localeCompare(b.name || "");
            });
        }
        return all.map(e => ({ e: e, s: _score(e, q) })).filter(r => r.s > 0).sort((a, b) => b.s - a.s).map(r => r.e);
    }
}
