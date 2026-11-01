pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Discovers bars under bars/ (any subfolder containing shell.qml) and
// tracks which one is currently active via the state file switch-bar.sh
// writes to. watchChanges keeps this live if the file changes externally.
QtObject {
    id: root

    readonly property string barsPath: "~/quickdots/bars"
    property var barNames: []

    property Process _scanProc: Process {
        command: ["sh", "-c", "for d in " + root.barsPath + "/*/; do [ -f \"$d/shell.qml\" ] && basename \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").map(s => s.trim()).filter(s => s.length > 0).sort();
                // Only replace on a real change: a new array resets every
                // view on it, destroying delegates whose BarTheme FileViews
                // may still be loading -- that crashes Quickshell 0.3.1.
                if (names.join("\n") !== root.barNames.join("\n")) root.barNames = names;
            }
        }
    }

    function rescan() {
        _scanProc.running = false;
        _scanProc.running = true;
    }

    Component.onCompleted: rescan()

    property string activeBar: "quickbar"

    property FileView _stateFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickdots/active-bar"
        printErrors: false
        watchChanges: true
        onLoaded: {
            const t = _stateFile.text().trim();
            if (t.length) root.activeBar = t;
        }
        onFileChanged: reload()
    }
}
