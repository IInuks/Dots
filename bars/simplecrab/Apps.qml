pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Root-Singleton (Begruendung siehe Colors.qml). Kapselt Fuzzy-Suche und
// Nutzungshaeufigkeit der Desktop-Eintraege fuer den Launcher.
QtObject {
    id: root

    // id -> { count: int, lastUsed: number(epoch ms) }
    property var _usage: ({})

    // FileView als benannte Property angelegt statt als nacktes Kind --
    // ein "nacktes" FileView{} unter einem QtObject-Root scheitert an
    // "Cannot assign to non-existent default property".
    property FileView _stateFile: FileView {
        id: stateFile
        path: Quickshell.statePath(Settings.launcherStateFile)
        watchChanges: false
        onLoaded: root._parseUsage(text())
        onLoadFailed: error => {
            root._usage = {};
        }
    }

    function _parseUsage(text) {
        try {
            root._usage = JSON.parse(text) || {};
        } catch (e) {
            root._usage = {};
        }
    }

    function _persist() {
        stateFile.setText(JSON.stringify(root._usage));
    }

    // Von AppList beim Start eines Eintrags aufgerufen.
    function recordUsage(id) {
        const entry = root._usage[id] || {
            count: 0,
            lastUsed: 0
        };
        entry.count += 1;
        entry.lastUsed = Date.now();
        root._usage[id] = entry;
        root._persist();
    }

    function _score(entry, needle) {
        const name = (entry.name || "").toLowerCase();
        const generic = (entry.genericName || "").toLowerCase();
        const keywords = (entry.keywords || []).join(" ").toLowerCase();

        if (name === needle)
            return 100;
        if (name.startsWith(needle))
            return 80;
        if (name.includes(needle))
            return 60;
        if (generic.includes(needle))
            return 40;
        if (keywords.includes(needle))
            return 20;
        return 0;
    }

    // Liefert eine sortierte Liste von DesktopEntry-Objekten.
    // Leere Suche: zuletzt/haeufig genutzt zuerst, sonst alphabetisch.
    // Nicht-leere Suche: nach Fuzzy-Score sortiert.
    function list(query) {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const needle = (query || "").trim().toLowerCase();

        if (needle.length === 0) {
            return all.slice().sort((a, b) => {
                const ua = root._usage[a.id];
                const ub = root._usage[b.id];
                const ca = ua ? ua.count : 0;
                const cb = ub ? ub.count : 0;
                if (ca !== cb)
                    return cb - ca;
                const la = ua ? ua.lastUsed : 0;
                const lb = ub ? ub.lastUsed : 0;
                if (la !== lb)
                    return lb - la;
                return (a.name || "").localeCompare(b.name || "");
            });
        }

        return all.map(e => ({
                    entry: e,
                    score: root._score(e, needle)
                })).filter(r => r.score > 0).sort((a, b) => b.score - a.score).map(r => r.entry);
    }
}
