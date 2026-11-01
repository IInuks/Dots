pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Scans .desktop files across XDG_DATA_DIRS once at startup for the
// launcher's live search -- one shell pass concatenates every file behind
// a marker line so this only needs a single process + one parse pass.
// Adapted verbatim from bars/quickbar/DesktopEntries.qml (same author's
// own prior work in this repo) -- no logic changes needed, only the file
// name. NOT called DesktopEntries.qml here: Quickshell ships its own
// built-in `DesktopEntries` type, and any file in this repo that also
// `import Quickshell` (LauncherWindow.qml does, for Quickshell.screens)
// silently resolves a bare `DesktopEntries` reference to that builtin
// instead of this singleton -- no error, just `.apps`/`.ready` reading as
// undefined forever (memory: feedback_qml_singleton_name_shadows_builtin,
// hit live while testing this exact file before the rename: `TypeError:
// Cannot read property 'length' of undefined` on DesktopEntries.apps).
// quickdots/menu independently hit the same trap and named its own copy
// of this logic AppEntries.qml for the same reason -- matched here.
QtObject {
    id: root

    property var apps: [] // [{id, name, exec, icon, terminal}]
    property bool ready: false

    readonly property string _marker: "@@LUCID_APP_ENTRY@@"

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
