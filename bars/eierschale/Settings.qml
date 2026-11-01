pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Alles, was im Einstellungs-Menü ("Werkbank") verstellbar ist, landet in
// ~/.local/state/quickshell/.../eierschale.json und überlebt Neustarts.
Singleton {
    id: root

    property alias data: adapter

    FileView {
        id: file
        path: Quickshell.statePath("eierschale.json")
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
            // "wallpaper" | "schoko" | "ostern" | "mitternacht" | "minze"
            property string themeMode: "wallpaper"
            // welcher der Wallpaper-Farbkandidaten Akzent ist (-1 = automatisch)
            property int accentPick: -1
            property bool floating: true
            property int radius: 18
            property real opacity: 0.92
            property real animSpeed: 1.0      // 0 = aus, 0.5 schnell, 1 normal, 1.6 gemütlich
            property bool showSeconds: false
            property bool eggWobble: true      // Ei wackelt alle 45 s kurz
            property bool dim: true            // Hintergrund abdunkeln bei Menüs
        }
    }
}
