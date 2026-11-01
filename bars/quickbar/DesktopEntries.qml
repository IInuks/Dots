pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Scans .desktop files across XDG_DATA_DIRS once at startup for the
// launcher's live search. One shell pass concatenates every file behind a
// marker line so we only need a single process + one parse pass.
QtObject {
    id: root

    property var apps: [] // [{id, name, exec, icon, terminal}]
    property bool ready: false

    readonly property string _marker: "@@QUICKBAR_DESKTOP_FILE@@"

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
