import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors bars/drop: that shell derives its palette from the current
// wallpaper (or a preset) and writes the resolved colors to
// ~/.local/state/drop/palette.json (see its Theme.qml, "Export").
// Read-only here, watched so the menu recolors with the wallpaper.
QtObject {
    id: root

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/drop/palette.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            property string surface: "#06131d"
            property string foreground: "#e4f6ff"
            property string accent: "#4fd1e8"
            property real barOpacity: 0.93
        }
    }

    readonly property string surface: _file.adapter.surface
    readonly property string foreground: _file.adapter.foreground
    readonly property string accent: _file.adapter.accent
    readonly property real barOpacity: _file.adapter.barOpacity
}
