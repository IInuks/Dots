import QtQuick
import Quickshell
import Quickshell.Io

// Read-only mirror for any custom-<slug> bar (built via the "Eigene" tab).
// Reads that bar's own config (~/.local/state/quickdots/custom-bars/
// <slug>.json) for theme.mode, and -- only when it's "adaptive" -- overlays
// live pywal colors (~/.cache/wal/colors.json), the same source
// CustomBarRoot.qml itself reads and that shellwall keeps current on every
// wallpaper change (see shellwall/Config.qml's runPywal). Non-adaptive
// modes just mirror the config's own stored colors. `slug` is set by
// BarTheme.qml's _live Loader after load, since one file here serves every
// custom-* bar rather than being bar-specific like the others in this
// folder.
QtObject {
    id: root

    property string slug: ""

    property FileView _cfg: FileView {
        path: root.slug.length ? (Quickshell.env("HOME") + "/.local/state/quickdots/custom-bars/" + root.slug + ".json") : ""
        printErrors: false
        watchChanges: true
        adapter: JsonAdapter {
            property var theme: ({ mode: "dark", surface: "#1c1c26", foreground: "#e8e8f0", accent: "#5b8cff", opacity: 0.9 })
        }
        onFileChanged: reload()
    }

    property FileView _wal: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        printErrors: false
        watchChanges: true
        property var parsed: null
        onLoaded: {
            try { parsed = JSON.parse(text()); } catch (e) { parsed = null; }
        }
        onFileChanged: reload()
    }

    readonly property bool _adaptive: root._cfg.adapter.theme.mode === "adaptive"

    readonly property color surface: root._adaptive && root._wal.parsed ? root._wal.parsed.special.background : (root._cfg.adapter.theme.surface || "#1c1c26")
    readonly property color foreground: root._adaptive && root._wal.parsed ? root._wal.parsed.special.foreground : (root._cfg.adapter.theme.foreground || "#e8e8f0")
    readonly property color accent: root._adaptive && root._wal.parsed ? root._wal.parsed.colors.color4 : (root._cfg.adapter.theme.accent || "#5b8cff")
    readonly property real barOpacity: root._cfg.adapter.theme.opacity !== undefined ? root._cfg.adapter.theme.opacity : 0.9
}
