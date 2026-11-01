import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors bars/eierschale: that shell derives its palette from the current
// wallpaper and writes the resolved colors to
// ~/.local/state/eierschale/palette.json (see its Theme.qml, "Export").
// Read-only here, watched so the menu recolors with the wallpaper.
QtObject {
    id: root

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/eierschale/palette.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            property string surface: "#1f140f"
            property string foreground: "#fff3e6"
            property string accent: "#ff7a1a"
            property real barOpacity: 0.92
        }
    }

    readonly property string surface: _file.adapter.surface
    readonly property string foreground: _file.adapter.foreground
    readonly property string accent: _file.adapter.accent
    readonly property real barOpacity: _file.adapter.barOpacity
}
