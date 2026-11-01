pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Alles, was im Labor (Einstellungen) verstellbar ist. Liegt in
// ~/.local/state/quickshell/by-shell/<id>/drop.json und überlebt Neustarts.
Singleton {
    id: root

    property alias data: adapter

    FileView {
        id: file
        path: Quickshell.statePath("drop.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            // "wallpaper" | "tiefsee" | "lagune" | "regen" | "tinte"
            property string themeMode: "wallpaper"
            property int accentPick: -1          // Wallpaper-Kandidat als Akzent, -1 = automatisch
            property bool film: true             // durchgehender Wasserfilm am oberen Rand
            property real opacity: 0.93
            property real animSpeed: 1.0         // 0 = aus, 0.6 flott, 1 normal, 1.6 zäh (Honig)
            property bool showSeconds: false
            property bool ripples: true          // Wellenring bei jedem Klick
            property bool dim: true              // Hintergrund abdunkeln bei Menüs
            property var layout: []              // gespeicherte Anordnung der Perlen (Arrange.qml), [] = Standard
        }
    }
}
