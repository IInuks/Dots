import QtQuick
import Quickshell
import Quickshell.Io
import "Components"

// Root des shellwall-Widgets. Haelt den App-Zustand (Wallpaper-Liste,
// Aufloesungs-Cache), scannt den Wallpaper-Ordner, setzt Wallpaper via swww
// und stellt einen IPC-Handler zum Ein-/Ausblenden des Overlays bereit.
ShellRoot {
    id: root

    Config { id: config }

    property string current: ""
    property var wallpapers: []
    property var resolutionCache: ({})
    property int resolutionVersion: 0

    function basename(path) {
        return path.substring(path.lastIndexOf("/") + 1);
    }

    function resolutionFor(path) {
        resolutionVersion; // Binding-Abhaengigkeit fuer Re-Evaluierung
        if (!path) return "";
        return root.resolutionCache[path] || "…";
    }

    // Loest die Bildaufloesung per `identify` (ImageMagick) auf und cached sie.
    // Wird debounced vom Overlay aus aufgerufen, daher genuegt ein einzelner
    // Process ohne Warteschlange.
    function requestResolution(index) {
        const path = root.wallpapers[index];
        if (!path || root.resolutionCache[path] || resolveProcess.running) return;
        resolveProcess.targetPath = path;
        resolveProcess.command = ["identify", "-format", "%wx%h", path];
        resolveProcess.running = true;
    }

    function setWallpaper(path) {
        root.current = path;
        Quickshell.execDetached([
            config.wallpaperBinary, "img", path,
            "--transition-type", config.transitionType,
            "--transition-fps", String(config.transitionFps)
        ]);
        // haelt shellbars adaptives Theme (liest ~/.cache/wal/colors.json)
        // in Sync, genau wie quickwalls bisheriges applyPywal.
        if (config.runPywal) {
            Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
        }
        if (config.runMatugen) {
            Quickshell.execDetached(["matugen", "image", path, "--mode", "dark", "--source-color-index", "0", "--quiet"]);
        }
    }

    function refreshWallpapers() {
        if (!listProcess.running) listProcess.running = true;
    }

    Process {
        id: listProcess
        command: ["ls", "-1", config.wallpaperDir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const extPattern = new RegExp("\\.(" + config.extensions.join("|") + ")$", "i");
                const names = this.text.split("\n")
                    .map(n => n.trim())
                    .filter(n => extPattern.test(n));
                root.wallpapers = names.map(n => config.wallpaperDir + "/" + n);
                if (root.current === "" && root.wallpapers.length > 0) {
                    root.current = root.wallpapers[0];
                }
            }
        }
    }

    Process {
        id: resolveProcess
        property string targetPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const dims = this.text.trim();
                if (dims.length > 0) {
                    root.resolutionCache[resolveProcess.targetPath] = dims.replace("x", " × ");
                    root.resolutionVersion++;
                }
            }
        }
    }

    CoverflowOverlay {
        id: overlay
        config: config
        appState: root
    }

    IpcHandler {
        target: "coverflow"
        function toggle(): void {
            overlay.toggle();
        }
    }
}
