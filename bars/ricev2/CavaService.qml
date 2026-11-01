pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bar prompt section 6's audio visualizer -- cava wrapped in raw-ascii
// output mode, same approach bars/lucid/CavaService.qml already proved on
// this exact machine (real cava 1.0.0 binary + pipewire, no
// pulseaudio/pipewire-pulse needed -- verified there with a real 440Hz
// test tone producing a sane spectrum). `bars`/`framerate` here match the
// bar prompt's own values (14/30) and the real skwd-bar's own
// ext/cava/cava-bar.conf (checked against github.com/liixini/skwd, not
// guessed) rather than lucid's 20/60.
//
// [input] isn't in the bar prompt's cava.conf snippet (it only lists
// [general]/[output] keys, same as the real skwd-bar file) -- added
// anyway, same as lucid: this system has no PulseAudio-compatible input
// for cava to autodetect by default, and `method = pipewire` is the
// proven-working native input here.
//
// `levels` is 0..1 per bar (already divided by ascii_max_range); the bar
// prompt's own smoothing formula ("display += (neu − display) × 0.45")
// is a display-layer concern, not cava's, so it's applied in
// Bar/lyrics/LyricsIsland.qml, not here -- same split as lucid's
// CavaService (raw levels) vs. its CavaBars view (smoothing itself).
QtObject {
    id: root

    readonly property int barCount: 14
    property var levels: [] // barCount reals, 0..1, [] while inactive

    property bool active: false
    onActiveChanged: root._sync()
    function _sync() {
        _proc.running = root.active;
        if (!root.active)
            root.levels = [];
    }

    readonly property string _configPath: Quickshell.env("HOME") + "/.cache/ricev2/cava.conf"
    readonly property string _configText: "[general]\nbars = " + root.barCount + "\nframerate = 30\n\n[input]\nmethod = pipewire\nsource = auto\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nbar_delimiter = 59\n"

    property FileView _configFile: FileView {
        id: configFile
        path: root._configPath
        printErrors: false
        atomicWrites: true
        onLoadFailed: error => configFile.setText(root._configText)
        onLoaded: {
            if (configFile.text() !== root._configText)
                configFile.setText(root._configText);
        }
    }

    property Process _proc: Process {
        id: proc
        command: ["cava", "-p", root._configPath]
        stdout: SplitParser {
            onRead: line => root._onLine(line)
        }
        onExited: {
            if (root.active)
                _restart.start();
        }
    }

    // Same auto-restart-on-death shape as lucid's CavaService -- if cava
    // (or the pipewire connection under it) dies while the lyrics island
    // still wants it, retry in a second instead of leaving the
    // visualizer silently frozen.
    property Timer _restart: Timer {
        interval: 1000
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }

    function _onLine(line) {
        const parts = line.split(";").filter(p => p.length > 0).map(Number);
        if (parts.length === 0)
            return;
        root.levels = parts.map(v => Math.max(0, Math.min(1, v / 100)));
    }
}
