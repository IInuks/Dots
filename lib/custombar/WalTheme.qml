import QtQuick
import Quickshell
import Quickshell.Io

// Live pywal palette, same source (~/.cache/wal/colors.json) and field
// mapping as bars/shellbar/Theme.qml. shellwall runs `wal -i <path> -n -q`
// on every wallpaper change (see shellwall/Config.qml's runPywal), so this
// always reflects the *currently active* wallpaper -- no manual wallpaper
// path to track or re-resolve on save. Not a singleton -- see
// ModuleRegistry.qml's top comment on sideways/symlinked imports breaking
// singleton property access; every consumer just instantiates its own copy.
QtObject {
    id: root

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

    readonly property color surface: root._wal.parsed ? root._wal.parsed.special.background : "#1c1c26"
    readonly property color foreground: root._wal.parsed ? root._wal.parsed.special.foreground : "#e8e8f0"
    readonly property color accent: root._wal.parsed ? root._wal.parsed.colors.color4 : "#5b8cff"
}
