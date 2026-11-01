pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Mango's global blur options for the "Blur" tab. Values are parsed from
// ~/.config/mango/config.conf; set() updates the value here right away and,
// coalesced, runs scripts/set-blur.sh (rewrites the line + reload_config),
// so the real blur on screen follows the sliders live.
//
// Mango clamps brightness/contrast/saturation to 0..1 and noise to 0..1
// (parse_config.h), so the tab uses exactly those ranges.
QtObject {
    id: root

    readonly property string confPath: Quickshell.env("HOME") + "/.config/mango/config.conf"

    property bool blur: true
    property bool blurLayer: true
    property bool blurOptimized: true
    property real passes: 3
    property real radius: 6
    property real noise: 0.02
    property real brightness: 0.9
    property real contrast: 0.9
    property real saturation: 1.0

    readonly property var _keys: ({
        blur: "blur", blurLayer: "blur_layer", blurOptimized: "blur_optimized",
        passes: "blur_params_num_passes", radius: "blur_params_radius",
        noise: "blur_params_noise", brightness: "blur_params_brightness",
        contrast: "blur_params_contrast", saturation: "blur_params_saturation"
    })
    readonly property var _defaults: ({
        blur: true, blurLayer: true, blurOptimized: true, passes: 3, radius: 6,
        noise: 0.02, brightness: 0.9, contrast: 0.9, saturation: 1.0
    })

    property var _pending: ({})
    property string lastError: ""

    function set(prop: string, value): void {
        root[prop] = value;
        const p = root._pending;
        p[prop] = value;
        root._pending = p;
        root._writeTimer.restart();
    }

    function resetDefaults(): void {
        for (const k in root._defaults) set(k, root._defaults[k]);
    }

    function _format(prop, v) {
        if (typeof v === "boolean") return v ? "1" : "0";
        if (prop === "passes" || prop === "radius") return String(Math.round(v));
        return Number(v).toFixed(2);
    }

    // slider drags: one write per 150 ms (each write = one config reload)
    property Timer _writeTimer: Timer {
        interval: 150
        onTriggered: {
            if (root._writer.running) { restart(); return; }
            const args = [];
            for (const k in root._pending) args.push(root._keys[k] + "=" + root._format(k, root._pending[k]));
            root._pending = ({});
            if (args.length === 0) return;
            root._writer.command = [Quickshell.shellDir + "/scripts/set-blur.sh"].concat(args);
            root._writer.running = true;
        }
    }

    property Process _writer: Process {
        stderr: StdioCollector { onStreamFinished: root.lastError = text.trim() }
    }

    function refresh(): void { root._file.reload(); }

    property FileView _file: FileView {
        path: root.confPath
        printErrors: false
        onLoaded: {
            // don't snap sliders back while our own writes are in flight
            if (root._writeTimer.running || root._writer.running) return;
            const values = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^\s*(blur\w*)\s*=\s*([0-9.]+)/);
                if (m) values[m[1]] = parseFloat(m[2]);
            }
            for (const prop in root._keys) {
                const v = values[root._keys[prop]];
                if (v === undefined) continue;
                root[prop] = typeof root._defaults[prop] === "boolean" ? v !== 0 : v;
            }
        }
    }
}
