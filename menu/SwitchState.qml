pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Drives scripts/switch-bar.sh and turns its stdout progress lines into a
// step index the status line in the menu's bottom row (shell.qml) shows
// live. Every stdout/stderr line also lands in `log` (the last error
// line is shown there on failure).
QtObject {
    id: root

    readonly property var stepLabels: [
        "Alte Bar beenden",
        "Neue Bar starten",
        "Config angepasst",
        "Keybinds aktualisiert"
    ]

    property int currentStep: -1
    property bool running: false
    property bool started: false   // switchTo() actually launched the script
    property bool done: false      // script exited (see failed for how)
    property bool failed: false
    property int exitCode: 0
    property string targetBar: ""
    property var log: []

    property Process _proc: Process {
        id: proc
        stdout: SplitParser {
            onRead: line => root._onLine(line, false)
        }
        stderr: SplitParser {
            onRead: line => root._onLine(line, true)
        }
        onExited: (exitCode, exitStatus) => {
            root.running = false;
            root.done = true;
            root.exitCode = exitCode;
            if (exitCode !== 0) root.failed = true;
            root._append((exitCode === 0 ? "✓ beendet (Exit 0)" : "✗ abgebrochen (Exit " + exitCode + ")"), exitCode !== 0);
        }
    }

    function switchTo(barName) {
        if (root.running || !barName || barName === BarsModel.activeBar) return;
        root.clear();
        root.targetBar = barName;
        root.started = true;
        root.running = true;
        root._append("$ switch-bar.sh " + barName, false);
        proc.command = [Quickshell.shellDir + "/scripts/switch-bar.sh", barName];
        proc.running = true;
    }

    // Forget the last run (wizard reset / going back from "Anwenden").
    function clear() {
        if (root.running) return;
        root.currentStep = -1;
        root.started = false;
        root.done = false;
        root.failed = false;
        root.exitCode = 0;
        root.targetBar = "";
        root.log = [];
    }

    function _append(text, isError) {
        root.log = root.log.concat([{ text: text, error: isError }]);
    }

    function _onLine(line, isError) {
        root._append(line, isError);
        const idx = root.stepLabels.indexOf(line.trim());
        if (idx !== -1) root.currentStep = idx;
    }
}
