pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Launcher assignments for the "Launcher" tab: which app launcher each bar
// uses on SUPER+space. Read through scripts/launchers.py info (launcher
// list from launchers/hosts/ + launchers/info.json, each bar's default, the
// saved assignments in ~/.local/state/quickdots/launchers.json), changed
// through scripts/set-launcher.sh, whose progress lines tick off
// stepLabels the same way SwitchState does for switch-bar.sh.
//
// Launcher ids: "appsearch" (the menu's own app search, SearchState) or a
// bar name (that bar's launcher; for any other bar it runs alone through
// launcher-host.sh).
QtObject {
    id: root

    readonly property string scriptDir: Quickshell.shellDir + "/scripts/"

    property var launchers: []     // [{ id, bar, title, description }]
    property var own: ({})         // bar -> has its own launcher
    property var effectiveMap: ({}) // bar -> launcher id in use
    property var assignments: ({}) // bar -> launcher id (explicit only)

    readonly property var ids: launchers.map(l => l.id)

    function find(id) {
        return root.launchers.find(l => l.id === id) || null;
    }
    function titleOf(id) {
        const l = root.find(id);
        return l && l.title ? l.title : "";
    }
    function descriptionOf(id) {
        const l = root.find(id);
        return l && l.description ? l.description : "";
    }
    // Shown name: the bar a launcher comes from, or "App-Suche".
    function nameOf(id) {
        return id === "appsearch" ? "App-Suche" : id;
    }

    function defaultFor(bar) {
        return root.own[bar] ? bar : "appsearch";
    }
    function effective(bar) {
        const e = root.effectiveMap[bar];
        return e !== undefined ? e : root.defaultFor(bar);
    }
    function isAssigned(bar) {
        return root.assignments[bar] !== undefined;
    }
    // Bars currently using launcher `id`.
    function barsUsing(id) {
        return Object.keys(root.effectiveMap).filter(b => root.effectiveMap[b] === id).sort();
    }

    function refresh() {
        if (_infoProc.running) return;
        _infoProc.running = true;
    }
    Component.onCompleted: refresh()

    property Process _infoProc: Process {
        command: [root.scriptDir + "launchers.py", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try { d = JSON.parse(text); } catch (e) { return; }
                // Only replace on a real change -- a new array resets the
                // list view (and the BarThemes in its rows, see BarsModel).
                const l = d.launchers || [];
                if (JSON.stringify(l) !== JSON.stringify(root.launchers)) root.launchers = l;
                root.own = d.own || {};
                root.effectiveMap = d.effective || {};
                root.assignments = d.assignments || {};
            }
        }
    }

    // -- Assigning (set-launcher.sh) --------------------------------------

    readonly property var stepLabels: [
        "Zuweisung gespeichert",
        "Launcher gestartet",
        "Keybinds aktualisiert"
    ]

    property int currentStep: -1
    property bool running: false
    property bool started: false
    property bool done: false
    property bool failed: false
    property int exitCode: 0
    property string targetBar: ""
    property string targetLauncher: ""
    property var log: []

    property Process _setProc: Process {
        stdout: SplitParser { onRead: line => root._onLine(line, false) }
        stderr: SplitParser { onRead: line => root._onLine(line, true) }
        onExited: (exitCode, exitStatus) => {
            root.running = false;
            root.done = true;
            root.exitCode = exitCode;
            root.failed = exitCode !== 0;
            root.refresh();
        }
    }

    // launcher = an id from `ids`, or "default".
    function assign(bar, launcher) {
        if (root.running || !bar || !launcher) return;
        root.clear();
        root.targetBar = bar;
        root.targetLauncher = launcher === "default" ? root.defaultFor(bar) : launcher;
        root.started = true;
        root.running = true;
        _setProc.command = [root.scriptDir + "set-launcher.sh", bar, launcher];
        _setProc.running = true;
    }

    function clear() {
        if (root.running) return;
        root.currentStep = -1;
        root.started = false;
        root.done = false;
        root.failed = false;
        root.exitCode = 0;
        root.targetBar = "";
        root.targetLauncher = "";
        root.log = [];
    }

    function _onLine(line, isError) {
        root.log = root.log.concat([{ text: line, error: isError }]);
        const idx = root.stepLabels.indexOf(line.trim());
        if (idx !== -1) root.currentStep = idx;
    }

    // -- Trying a launcher out ("Ausprobieren") ---------------------------

    // Opens launcher `id` right now, without assigning it: the app search
    // directly, the active bar's own launcher through its SUPER+space
    // command, any other through a host started for it (try-launcher.sh).
    // A leftover host is cleaned up by the next sync (handleOpen()).
    function tryOut(id) {
        if (id === "appsearch") {
            SearchState.forceOpen();
            return;
        }
        Quickshell.execDetached([root.scriptDir + "try-launcher.sh", id]);
    }

    // Called when the menu opens: re-read, and stop a host that was only
    // started to try a launcher out.
    function handleOpen() {
        root.refresh();
        if (!root.running) {
            root.clear();
            Quickshell.execDetached([root.scriptDir + "launcher-host.sh", "sync"]);
        }
    }
}
