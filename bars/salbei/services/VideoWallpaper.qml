pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Optional video wallpaper: mpvpaper playing ~/Videos/wallpaper.{mp4,webm,mkv} on all
// outputs. Your normal wallpaper tool keeps running underneath; this only adds a layer.
Singleton {
    id: root

    property string video: ""
    readonly property bool available: video !== ""
    readonly property bool active: proc.running

    function toggle() {
        if (!available) return;
        proc.running = !proc.running;
    }

    Process {
        id: proc
        command: ["mpvpaper", "-o", "no-audio loop panscan=1.0", "*", root.video]
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v mpvpaper >/dev/null && for f in \"$HOME\"/Videos/wallpaper.mp4 \"$HOME\"/Videos/wallpaper.webm \"$HOME\"/Videos/wallpaper.mkv; do [ -f \"$f\" ] && { echo \"$f\"; break; }; done"]
        stdout: StdioCollector { onStreamFinished: root.video = text.trim() }
    }
}
