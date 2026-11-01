pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ambient audio visualizer for the Media panel -- wraps `cava` in raw-ascii
// output mode, the standard way to pull bar-height numbers out of it
// without its ncurses UI. `cava` only takes a config *file* (no inline
// CLI flags for input/output), so this writes one once to
// ~/.cache/lucidbar/cava.conf -- regenerated every run, not user-editable,
// unlike Config.qml's persisted ~/.config/lucidbar/config.json.
//
// Live-verified against the real cava 1.0.0 binary + this system's
// pipewire on this machine (no pulseaudio/pipewire-pulse needed -- cava
// has a native `method = pipewire` input): a 440Hz test tone played via
// `pw-play` produced a real, sensible spectrum on stdout in exactly the
// shape parsed below (`0;2;100;7;5;4;` -- semicolon after every value,
// including the last one, one line per frame). `bars` must be even for
// stereo input; using `channels = mono` sidesteps that entirely and gives
// one combined spectrum, which is all a small bar-pill visualizer needs.
//
// Only runs while at least one Media panel is open (refcounted via
// acquire()/release(), called from Panels/MediaPanel.qml's `active`
// passthrough) -- unlike the always-on Pipewire/UPower trackers the
// System panel reads from directly, this is a continuous 60fps capture
// process and not worth keeping alive behind a closed panel.
QtObject {
    id: root

    readonly property int barCount: 20
    property var levels: [] // barCount reals, 0..1, [] while inactive

    property int _refCount: 0
    function acquire() {
        root._refCount++;
        root._sync();
    }
    function release() {
        root._refCount = Math.max(0, root._refCount - 1);
        root._sync();
    }
    function _sync() {
        _proc.running = root._refCount > 0;
        if (root._refCount === 0)
            root.levels = [];
    }

    readonly property string _configPath: Quickshell.env("HOME") + "/.cache/lucidbar/cava.conf"
    readonly property string _configText: "[general]\nbars = " + root.barCount + "\nframerate = 60\nsensitivity = 100\n\n[input]\nmethod = pipewire\nsource = auto\n\n[output]\nmethod = raw\nchannels = mono\nmono_option = average\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nbar_delimiter = 59\n"

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
            if (root._refCount > 0)
                _restart.start();
        }
    }

    // Same auto-restart-on-death shape as MangoService's `mmsg watch`
    // process -- if cava (or the pipewire connection under it) dies while
    // a panel still wants it, try again in a second instead of leaving
    // the visualizer silently frozen.
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
