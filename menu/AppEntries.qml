pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Scans .desktop files across XDG_DATA_DIRS for the App-Suche popup.
// Self-contained copy of bars/quickbar/DesktopEntries.qml's approach --
// the menu never imports files from bars/ (see README), so it keeps its
// own tiny scanner instead. Deliberately NOT named "DesktopEntries":
// Quickshell itself ships a real built-in singleton of that exact name
// (Quickshell/DesktopEntries, a totally different .applications-based
// API) -- any file that also `import Quickshell` would then silently
// resolve the bare name to that built-in instead of this one.
QtObject {
    id: root

    property var apps: [] // [{id, name, exec, icon, terminal}]
    property bool ready: false

    readonly property string _marker: "@@QUICKDOTS_DESKTOP_FILE@@"

    function _dataDirs() {
        const xdg = Quickshell.env("XDG_DATA_DIRS") || "/usr/local/share:/usr/share";
        const home = Quickshell.env("HOME");
        const dirs = xdg.split(":").filter(d => d.length > 0).map(d => d + "/applications");
        dirs.push(home + "/.local/share/applications");
        return dirs;
    }

    property Process _scanProc: Process {
        running: true
        command: {
            const dirs = root._dataDirs();
            const dirList = dirs.map(d => "\"" + d + "\"").join(" ");
            const script = "for d in " + dirList + "; do " +
                "[ -d \"$d\" ] || continue; " +
                "for f in \"$d\"/*.desktop; do " +
                "[ -f \"$f\" ] || continue; " +
                "echo \"" + root._marker + "$f\"; cat \"$f\"; " +
                "done; done";
            return ["sh", "-c", script];
        }
        stdout: StdioCollector {
            onStreamFinished: root._parseAll(text)
        }
    }

    function _parseAll(blob) {
        const chunks = blob.split(root._marker).filter(c => c.length > 0);
        const seen = {};
        const results = [];
        for (const chunk of chunks) {
            const nl = chunk.indexOf("\n");
            if (nl < 0) continue;
            const path = chunk.slice(0, nl);
            const body = chunk.slice(nl + 1);
            const entry = root._parseDesktop(body, path);
            if (entry && !seen[entry.name]) {
                seen[entry.name] = true;
                results.push(entry);
            }
        }
        results.sort((a, b) => a.name.localeCompare(b.name));
        root.apps = results;
        root.ready = true;
    }

    function _parseDesktop(text, path) {
        const lines = text.split("\n");
        let inEntry = false;
        let name = "", exec = "", icon = "", hidden = false, terminal = false, noDisplay = false;
        for (const raw of lines) {
            const line = raw.trim();
            if (line.startsWith("[")) {
                if (inEntry) break; // stop at the next group after [Desktop Entry]
                inEntry = (line === "[Desktop Entry]");
                continue;
            }
            if (!inEntry) continue;
            if (line.startsWith("Name=") && name === "") name = line.slice(5);
            else if (line.startsWith("Exec=")) exec = line.slice(5);
            else if (line.startsWith("Icon=")) icon = line.slice(5);
            else if (line.startsWith("NoDisplay=")) noDisplay = line.slice(10).trim() === "true";
            else if (line.startsWith("Hidden=")) hidden = line.slice(7).trim() === "true";
            else if (line.startsWith("Terminal=")) terminal = line.slice(9).trim() === "true";
        }
        if (!name || !exec || hidden || noDisplay) return null;
        const cleanExec = exec.replace(/%[a-zA-Z]/g, "").trim();
        return { id: path, name, exec: cleanExec, icon, terminal };
    }

    function launch(app) {
        if (app.terminal) {
            Quickshell.execDetached(["kitty", "-e", "sh", "-c", app.exec]);
        } else {
            Quickshell.execDetached(["sh", "-c", app.exec]);
        }
    }
}
