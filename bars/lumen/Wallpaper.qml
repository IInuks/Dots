pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Root-Singleton (Begruendung siehe Colors.qml). Scannt Settings.wallpaperDir
// per `ls`, wendet ein Wallpaper per awww an (Nixpkgs-Nachfolger von swww,
// CLI identisch) und triggert danach pywal -- exakt dieselbe Kette wie
// ~/quickdots/shellwall/shell.qml (setWallpaper), nur ohne Coverflow-UI:
// hier reicht ein einfaches Grid (siehe Modules/Wallpaper/WallpaperPicker.qml).
QtObject {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/" + Settings.wallpaperDir
    property var files: []
    property string current: ""

    property var _tmpFiles: []

    function _isImage(name) {
        const lower = name.toLowerCase();
        return Settings.wallpaperExtensions.some(ext => lower.endsWith("." + ext));
    }

    function rescan() {
        if (_scanProc.running)
            return;
        _tmpFiles = [];
        _scanProc.running = true;
    }

    property Process _scanProc: Process {
        id: scanProc
        command: ["ls", "-1", root.dir]
        stdout: SplitParser {
            onRead: line => root._tmpFiles.push(line)
        }
        onExited: {
            const names = root._tmpFiles.filter(root._isImage).sort();
            root.files = names.map(n => root.dir + "/" + n);
            if (root.current === "" && root.files.length > 0)
                root.current = root.files[0];
        }
    }

    function apply(path) {
        if (!path)
            return;
        root.current = path;
        Quickshell.execDetached([Settings.wallpaperBinary, "img", path, "--transition-type", Settings.wallpaperTransitionType, "--transition-fps", String(Settings.wallpaperTransitionFps)]);
        // haelt Colors.qml (liest ~/.cache/wal/colors.json) in Sync.
        if (Settings.wallpaperRunPywal)
            Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
    }

    Component.onCompleted: root.rescan()
}
