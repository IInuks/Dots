pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backs the "Eigene" tab: lists saved custom bars, loads/edits one at a
// time (bound directly to configFile.adapter.* -- BarEditor reads/writes
// those properties straight, no separate JS copy to keep in sync), and
// drives the save/delete scripts that do the actual filesystem work
// (bars/custom-<slug>/ scaffolding, adapters/*.json), mirroring how
// SwitchState.qml drives switch-bar.sh.
QtObject {
    id: root

    readonly property string scriptsDir: Quickshell.shellDir + "/scripts"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickdots/custom-bars"

    property var list: []          // [{slug, name}, ...]
    property string editingSlug: "" // "" -> overview shown, not the editor
    property bool loaded: false
    property bool saving: false
    property string lastError: ""

    function refresh() {
        _listProc.running = false;
        _listProc.running = true;
    }
    Component.onCompleted: root.refresh()

    property Process _listProc: Process {
        command: [root.scriptsDir + "/list-custom-bars.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.list = JSON.parse(text); } catch (e) { root.list = []; }
            }
        }
    }

    function slugExists(slug) {
        return root.list.some(b => b.slug === slug);
    }

    function newSlug() {
        let n = root.list.length + 1;
        while (root.slugExists("bar" + n)) n++;
        return "bar" + n;
    }

    // Opens the editor for an existing bar, or a brand-new one if slug
    // isn't in the list yet (configFile's onLoadFailed then seeds defaults).
    function edit(slug) {
        root.loaded = false;
        root.editingSlug = slug;
    }

    function closeEditor() {
        root.editingSlug = "";
    }

    readonly property var _defaults: ({
        name: "Meine Bar",
        style: "bar",
        position: "top",
        zones: ({ left: [], center: [], right: [] }),
        theme: ({ mode: "dark", surface: "#1c1c26", foreground: "#e8e8f0", accent: "#5b8cff", opacity: 0.9, radius: 14 }),
        islands: ({
            left: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
            center: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
            right: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 })
        })
    })

    property FileView configFile: FileView {
        id: configFile
        path: root.editingSlug.length ? (root.stateDir + "/" + root.editingSlug + ".json") : ""
        printErrors: false
        watchChanges: false
        atomicWrites: true
        adapter: JsonAdapter {
            property string name: "Meine Bar"
            property string style: "bar"
            property string position: "top"
            property var zones: ({ left: [], center: [], right: [] })
            property var theme: ({ mode: "dark", surface: "#1c1c26", foreground: "#e8e8f0", accent: "#5b8cff", opacity: 0.9, radius: 14 })
            property var islands: ({
                left: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
                center: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
                right: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 })
            })
        }
        onLoaded: root.loaded = true
        onLoadFailed: error => {
            const d = root._defaults;
            adapter.name = d.name;
            adapter.style = d.style;
            adapter.position = d.position;
            adapter.zones = JSON.parse(JSON.stringify(d.zones));
            adapter.theme = JSON.parse(JSON.stringify(d.theme));
            adapter.islands = JSON.parse(JSON.stringify(d.islands));
            root.loaded = true;
        }
        onSaved: {
            _finalizeProc.command = [root.scriptsDir + "/save-custom-bar.sh", root.editingSlug];
            _finalizeProc.running = true;
        }
        onSaveFailed: error => {
            root.saving = false;
            root.lastError = "Speichern fehlgeschlagen (" + error + ")";
        }
    }

    function save() {
        if (!root.editingSlug || !root.loaded) return;
        root.saving = true;
        root.lastError = "";
        configFile.writeAdapter();
    }

    property Process _finalizeProc: Process {
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length) root.lastError = text.trim()
        }
        onExited: exitCode => {
            root.saving = false;
            if (exitCode === 0) {
                root.refresh();
                BarsModel.rescan();
            }
        }
    }

    function remove(slug) {
        _deleteProc.command = [root.scriptsDir + "/delete-custom-bar.sh", slug];
        _deleteProc.pendingSlug = slug;
        _deleteProc.running = true;
    }

    property Process _deleteProc: Process {
        property string pendingSlug: ""
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length) root.lastError = text.trim()
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                if (root.editingSlug === pendingSlug) root.editingSlug = "";
                root.refresh();
                BarsModel.rescan();
            }
        }
    }
}
