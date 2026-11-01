pragma Singleton
import QtQuick
import Quickshell

// App-Liste fuer die Wundertuete (Launcher). DesktopEntries fuellt sich
// asynchron, deshalb wird bei jeder Aenderung neu einsortiert.
Singleton {
    id: root

    property var all: []

    function _rebuild() {
        const v = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        v.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        all = v;
    }

    property Connections _watch: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root._rebuild();
        }
    }
    Component.onCompleted: _rebuild()

    // Treffer-Qualitaet: exakter Anfang > Wortanfang > Initialen > irgendwo
    function _score(e, q) {
        const name = (e.name || "").toLowerCase();
        if (name.startsWith(q))
            return 4;
        const words = name.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q)))
            return 3;
        if (words.map(w => w[0] || "").join("").startsWith(q))
            return 2;
        if (name.indexOf(q) !== -1)
            return 1;
        const extra = ((e.genericName || "") + " " + (e.keywords || []).join(" ")).toLowerCase();
        return extra.indexOf(q) !== -1 ? 0.5 : 0;
    }

    function search(query) {
        const q = (query || "").trim().toLowerCase();
        if (!q)
            return all;
        return all.map(e => ({ e: e, s: _score(e, q) }))
                  .filter(r => r.s > 0)
                  .sort((a, b) => b.s - a.s)
                  .map(r => r.e);
    }
}
