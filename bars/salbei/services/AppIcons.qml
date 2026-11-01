pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Resolves app icon names. Qt's own lookup misses most icons on Bedrock because
// /bedrock/cross/icons/hicolor ships a near-empty icon-theme.cache that Qt trusts,
// so the cross hicolor/pixmaps dirs are indexed once here as a fallback.
Singleton {
    id: root

    property var index: ({})            // name → file path
    property int revision: 0            // bump so bindings re-resolve after indexing

    function resolve(name) {
        revision; // dependency
        if (!name) return "";
        if (name.startsWith("/") || name.startsWith("file:")) return name.startsWith("/") ? "file://" + name : name;
        const viaTheme = Quickshell.iconPath(name, true);
        if (viaTheme !== "") return viaTheme;
        const p = index[name] ?? index[name.toLowerCase()];
        return p ? "file://" + p : "";
    }

    Process {
        running: true
        // preferred sizes first; the first hit per name wins
        command: ["sh", "-c",
            "for d in scalable 256x256 128x128 96x96 64x64 48x48 32x32; do " +
            "for r in /bedrock/cross/icons/hicolor ${HOME}/.local/share/icons/hicolor; do " +
            "[ -d \"$r/$d/apps\" ] && find \"$r/$d/apps\" -maxdepth 1 \\( -type f -o -type l \\); done; done; " +
            "find /bedrock/cross/pixmaps -maxdepth 1 \\( -type f -o -type l \\) 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const p of text.split("\n")) {
                    const m = p.match(/\/([^/]+)\.(svg|png|xpm)$/);
                    if (m && m[2] !== "xpm" && !out[m[1]]) out[m[1]] = p;
                }
                root.index = out;
                root.revision++;
            }
        }
    }
}
