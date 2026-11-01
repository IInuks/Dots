pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// App search over Quickshell's desktop entry index, ranked by match
// quality + how often you launched the app (counts persisted in the state
// dir, so the launcher learns your favourites).
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay).slice().sort((a, b) => a.name.localeCompare(b.name))

    function _score(e, q) {
        const n = e.name.toLowerCase();
        const g = (e.genericName || "").toLowerCase();
        const k = (e.keywords || []).join(" ").toLowerCase();
        const c = (e.comment || "").toLowerCase();
        let s = 0;
        if (n === q) s = 100;
        else if (n.startsWith(q)) s = 80;
        else if (n.split(/[\s\-_]/).some(w => w.startsWith(q))) s = 65;
        else if (n.includes(q)) s = 50;
        else if (g.includes(q) || k.includes(q)) s = 30;
        else if (c.includes(q)) s = 15;
        else {
            // loose subsequence match ("ffx" -> firefox)
            let i = 0;
            for (const ch of n) if (ch === q[i]) i++;
            s = i === q.length ? 8 : 0;
        }
        return s === 0 ? 0 : s + Math.min(20, root.count(e) * 2);
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return root.all.slice().sort((a, b) => root.count(b) - root.count(a) || a.name.localeCompare(b.name));
        return root.all.map(e => ({ e: e, s: root._score(e, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    // "=" prefix calculator shared by both launchers: "=2*(3+4)" -> "14".
    // Returns "" for anything that is not a plain arithmetic expression.
    function calc(query) {
        const expr = query.slice(1).replace(/,/g, ".").replace(/\^/g, "**").replace(/×/g, "*");
        if (!/^[0-9+\-*/().\s%*]+$/.test(expr) || expr.trim() === "")
            return "";
        try {
            const v = Function("'use strict'; return (" + expr + ")")();
            return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : "";
        } catch (e) {
            return "";
        }
    }

    function count(e) {
        return adapter.counts[e.id] || 0;
    }

    function launch(e) {
        const c = Object.assign({}, adapter.counts);
        c[e.id] = (c[e.id] || 0) + 1;
        adapter.counts = c;
        file.writeAdapter();
        e.execute();
    }

    // Deterministic accent per app for its icon-badge fallback.
    function hue(e) {
        let h = 0;
        for (const ch of e.name)
            h = (h * 31 + ch.charCodeAt(0)) >>> 0;
        return h;
    }

    FileView {
        id: file
        path: Quickshell.statePath("launches.json")
        printErrors: false
        onLoadFailed: writeAdapter()
        adapter: JsonAdapter {
            id: adapter
            property var counts: ({})
        }
    }
}
