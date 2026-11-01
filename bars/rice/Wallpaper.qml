pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Scans Config.wallpaperDir, applies a wallpaper via awww (nixpkgs' swww
// successor, CLI-identical -- same binary bars/lumen/Wallpaper.qml and
// quickdots/shellwall/shell.qml already call), and re-triggers BOTH color
// pipelines that read the new image: `wal -i <path> -n -q` (kitty/pywal,
// already wired via ~/.bashrc per this project's established convention)
// and Theme.regenerateAdaptive(path) (matugen -> bar/panel colors + the
// GTK/Qt templates configured in ~/.config/matugen/config.toml -- see
// README "System-Theming"). ~/.config/matugen/config.toml also has its own
// `[config.wallpaper] set = true`, so the matugen call below will ALSO set
// the wallpaper via awww as a side effect -- harmless (same path, awww on
// an already-current image is a no-op crossfade) and left alone rather
// than touching that shared file's existing behaviour for other bars
// (blobs-bar) that depend on it.
QtObject {
    id: root

    readonly property string dir: Config.ready ? Config.wallpaperDir : (Quickshell.env("HOME") + "/Pictures/Walpapers")
    property var files: []
    property string current: ""
    property bool applying: false

    property var _tmpFiles: []

    function _isImage(name) {
        const lower = name.toLowerCase();
        const exts = Config.ready ? Config.wallpaperExtensions : ["jpg", "jpeg", "png", "webp"];
        return exts.some(ext => lower.endsWith("." + ext));
    }

    function rescan() {
        if (_scanProc.running) return;
        _tmpFiles = [];
        _scanProc.command = ["ls", "-1", root.dir];
        _scanProc.running = true;
    }

    property Process _scanProc: Process {
        stdout: SplitParser { onRead: line => root._tmpFiles.push(line) }
        onExited: {
            const names = root._tmpFiles.filter(root._isImage).sort();
            root.files = names.map(n => root.dir + "/" + n);
            if (root.current === "" && root.files.length > 0)
                root.current = root.files[0];
        }
    }

    function apply(path) {
        if (!path) return;
        root.current = path;
        root.applying = true;
        Quickshell.execDetached([
            Config.wallpaperBinary, "img", path,
            "--transition-type", Config.transitionType,
            "--transition-fps", String(Config.transitionFps)
        ]);
        Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
        Theme.regenerateAdaptive(path);
        _applyingClear.restart();
    }

    // Just long enough for the WallpaperSwitcher grid to show a spinner
    // on the clicked thumbnail during the transition; not tied to any
    // real completion signal (awww/matugen/wal all run detached).
    property Timer _applyingClear: Timer {
        interval: 900
        onTriggered: root.applying = false
    }

    function applyRandom() {
        if (root.files.length === 0) return;
        let idx = Math.floor(Math.random() * root.files.length);
        if (root.files.length > 1 && root.files[idx] === root.current)
            idx = (idx + 1) % root.files.length;
        root.apply(root.files[idx]);
    }

    property Timer _slideshowTimer: Timer {
        interval: Math.max(1, Config.ready ? Config.slideshowIntervalMin : 30) * 60000
        running: Config.ready && Config.slideshowEnabled
        repeat: true
        onTriggered: root.applyRandom()
    }

    Component.onCompleted: root.rescan()
}
