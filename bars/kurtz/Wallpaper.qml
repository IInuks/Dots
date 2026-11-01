pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adaptive theme source: the current wallpaper's colors.
//
// Only runs while something asks for it (sky or accent set to "wallpaper").
// The wallpaper path comes from `awww query` and is fed to matugen whenever
// it changes. shellwall runs matugen after every `awww img`, which rewrites
// ~/.cache/ricev2/colors.json (and pywal ~/.cache/wal/colors.json): those
// files are watched so a switch there applies at once. The slow poll only
// catches wallpapers set some other way. matugen's Material palettes are deliberately
// muted, so we only take the *hues* (and a hint of chroma) from them; Theme
// turns those into Kurzgesagt-style deep skies and bright accents.
//
// matugen needs --prefer when spawned without a terminal: an image with
// several candidate source colors otherwise prompts on stdin and fails.
Singleton {
    id: root

    readonly property bool wanted: Config.s.sky === "wallpaper" || Config.s.accent === "wallpaper"

    property string path: ""
    property bool ready: false
    property string error: ""

    // Tone 70 of matugen's tonal palettes: saturated enough to read the hue.
    property color primary: "#38BDF8"
    property color secondary: "#3B82F6"
    property color tertiary: "#A855F7"

    // Forces a fresh matugen run (IPC "theme regen", Studio button).
    function regenerate() {
        root.path = "";
        queryProc.running = true;
    }

    function _query() {
        if (root.wanted && !queryProc.running)
            queryProc.running = true;
    }

    Timer {
        interval: 10000
        running: root.wanted
        repeat: true
        triggeredOnStart: true
        onTriggered: root._query()
    }

    // awww may still report the old image for a moment after `awww img`;
    // asking again shortly after catches that.
    Timer {
        id: settleTimer
        interval: 700
        onTriggered: root._query()
    }

    component CacheWatch: FileView {
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root._query();
            settleTimer.restart();
        }
    }
    CacheWatch { path: Quickshell.env("HOME") + "/.cache/ricev2/colors.json" }
    CacheWatch { path: Quickshell.env("HOME") + "/.cache/wal/colors.json" }

    // "DP-4: 2560x1440, scale: 1, currently displaying: image: /path"
    // -> first output wins (the colors are shell-wide).
    Process {
        id: queryProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /image:\s*(.+)$/m.exec(text);
                if (!m) {
                    if (!root.ready)
                        root.error = "awww meldet kein Bild";
                    return;
                }
                const p = m[1].trim();
                if (p !== root.path) {
                    root.path = p;
                    matugenProc.command = ["matugen", "image", p, "--json", "hex", "--mode", "dark",
                                           "--prefer", "saturation", "--dry-run"];
                    matugenProc.running = true;
                }
            }
        }
        onExited: code => {
            if (code !== 0 && !root.ready)
                root.error = "awww query fehlgeschlagen";
        }
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    root.error = "matugen lieferte kein JSON";
                    return;
                }
                const p = d.palettes;
                root.primary = p.primary["70"].color;
                root.secondary = p.secondary["70"].color;
                root.tertiary = p.tertiary["70"].color;
                root.error = "";
                root.ready = true;
            }
        }
    }
}
