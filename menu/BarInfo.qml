pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Text + preview data for the wizard's "Bar" step: title/description from
// each bar's README.md, an optional real screenshot (bars/<name>/preview.png),
// and the current wallpaper (awww query) as backdrop for generated mockups.
// rescan() is called every time the menu opens (shell.qml).
QtObject {
    id: root

    property var info: ({})
    property string wallpaper: ""

    function titleOf(name) {
        const i = root.info[name];
        return i && i.title ? i.title : "";
    }
    function descriptionOf(name) {
        const i = root.info[name];
        if (i && i.description) return i.description;
        if (name.startsWith("custom-")) return "Eigene Bar aus dem Baukasten (Schritt \"Eigene Bars\").";
        return "Keine Beschreibung vorhanden -- lege eine README.md in bars/" + name + "/ an.";
    }
    function previewOf(name) {
        const i = root.info[name];
        return i && i.preview ? i.preview : "";
    }

    function rescan() {
        _infoProc.running = false;
        _infoProc.running = true;
        _wallProc.running = false;
        _wallProc.running = true;
    }
    Component.onCompleted: rescan()

    property Process _infoProc: Process {
        command: [Quickshell.shellDir + "/scripts/bar-info.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.info = JSON.parse(text); } catch (e) { root.info = {}; }
            }
        }
    }

    // "DP-4: 2560x1440, scale: 1, currently displaying: image: /path.png"
    // webp is skipped: this Qt build has no webp plugin.
    property Process _wallProc: Process {
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                root.wallpaper = p.length && !p.toLowerCase().endsWith(".webp") ? p : "";
            }
        }
    }
}
