pragma Singleton
import QtQuick
import Quickshell

// Anordnung der Perlen. Eine Anordnung ist eine Liste von Gruppen:
//   { ids: ["vol", "lab"], pos: 0.8, gap: 0, wall: "" }
// Die Perlen einer Gruppe hängen nebeneinander; gap 0 = verschmolzen
// (sieht aus wie eine Perle). pos 0..1 legt die Gruppe zwischen linken
// (0) und rechten Rand (1); 0.5 = genau mittig. So bleibt eine Gruppe auch
// dann an ihrem Rand bzw. in der Mitte, wenn sich Breiten ändern.
// wall "l"/"r": die Gruppe klebt ohne Abstand an der Bildschirmwand und
// verbindet sich mit ihr (pos wird dann ignoriert).
//
// `groups` ist die Live-Anordnung, Settings.data.layout die gespeicherte
// ([] = Standard). Speichern/Zurücksetzen/Löschen im Anordnen-Modus.
Singleton {
    id: root

    readonly property var keys: ["spring", "tags", "title", "clock", "stats", "vol", "lab", "power"]
    readonly property var defaults: [
        { ids: ["spring", "tags", "title"], pos: 0, gap: 16, wall: "" },
        { ids: ["clock"], pos: 0.5, gap: 0, wall: "" },
        { ids: ["stats", "vol", "lab", "power"], pos: 1, gap: 16, wall: "" }
    ]

    property bool editing: false
    property string dragKey: ""          // die Perle, die gerade gezogen wird
    property var groups: defaults

    readonly property var saved: _clean(Settings.data.layout)
    readonly property bool hasSaved: (Settings.data.layout || []).length > 0
    readonly property bool dirty: JSON.stringify(groups) !== JSON.stringify(saved)

    // gespeicherte Anordnung übernehmen (beim Laden und wenn die Datei sich ändert)
    onSavedChanged: if (!editing) groups = saved

    function begin() { Ui.close(); editing = true; }
    function finish() { dragKey = ""; editing = false; }
    function save() { Settings.data.layout = JSON.parse(JSON.stringify(groups)); }
    function revert() { groups = saved; }
    function remove() { Settings.data.layout = []; groups = defaults; }

    // Gespeichertes prüfen: jede Perle genau einmal, fehlende hinten dran
    function _clean(l) {
        if (!l || !l.length) return defaults;
        const seen = {};
        const out = [];
        for (const g of l) {
            const ids = (g.ids || []).filter(k => keys.indexOf(k) >= 0 && !seen[k]);
            ids.forEach(k => seen[k] = true);
            if (ids.length)
                out.push({ ids: ids, pos: Math.max(0, Math.min(1, Number(g.pos) || 0)), gap: Math.max(0, Number(g.gap) || 0),
                           wall: g.wall === "l" || g.wall === "r" ? g.wall : "" });
        }
        for (const k of keys)
            if (!seen[k]) out.push({ ids: [k], pos: 1, gap: 0, wall: "" });
        return out;
    }
}
