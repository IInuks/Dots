import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors bars/fullshell/Theme.qml's palette + wallpaper-extraction logic,
// read-only, same convention as the other live adapters.
QtObject {
    id: root

    property FileView _settings: FileView {
        path: Quickshell.env("HOME") + "/.local/state/fullshell/settings.json"
        printErrors: false
        watchChanges: true
        adapter: JsonAdapter {
            property string themeMode: "adaptive"
            property string wallpaperPath: ""
            property real barOpacity: 0.78
        }
        onFileChanged: reload()
    }

    readonly property var dark: ({ surface: "#17142a", text: "#eae6ff", accent: "#7c5cff" })
    readonly property var light: ({ surface: "#ffffff", text: "#201a35", accent: "#6b3fe0" })

    property var adaptivePalette: null
    property string _lastExtractedPath: ""

    property string wallpaperPath: _settings.adapter.wallpaperPath
    onWallpaperPathChanged: if (wallpaperPath) root._extractFromWallpaper(wallpaperPath)
    Component.onCompleted: if (wallpaperPath) root._extractFromWallpaper(wallpaperPath)

    property Process _extractProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root._onExtractOutput(text)
        }
    }
    property string _pendingExtractPath: ""

    // See bars/fullshell/Theme.qml: reassigning `command` while a
    // previous run is still in flight is a no-op, so stop first and defer
    // the restart a tick so the old process actually tears down.
    property Timer _restartTimer: Timer {
        interval: 0
        onTriggered: {
            root._extractProc.command = ["magick", root._pendingExtractPath, "-resize", "150x150", "-colors", "10", "-unique-colors", "txt:-"];
            root._extractProc.running = true;
        }
    }

    function _extractFromWallpaper(path) {
        if (!path || path === root._lastExtractedPath) return;
        root._lastExtractedPath = path;
        root._pendingExtractPath = path;
        root._extractProc.running = false;
        root._restartTimer.restart();
    }

    function _onExtractOutput(text) {
        const colors = [];
        const re = /\((\d+),\s*(\d+),\s*(\d+)/g;
        let m;
        while ((m = re.exec(text)) !== null) {
            colors.push({ r: parseInt(m[1]), g: parseInt(m[2]), b: parseInt(m[3]) });
        }
        if (colors.length >= 3) root.adaptivePalette = root._buildAdaptive(colors);
        else root._lastExtractedPath = "";
    }

    function _rgbToHsl(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        const max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h = 0, s = 0;
        const l = (max + min) / 2;
        const d = max - min;
        if (d !== 0) {
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
            else if (max === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h *= 60;
        }
        return { h, s, l };
    }

    function _hslToRgb(h, s, l) {
        h = ((h % 360) + 360) % 360 / 360;
        function hue2rgb(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        }
        let r, g, b;
        if (s === 0) { r = g = b = l; }
        else {
            const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            const p = 2 * l - q;
            r = hue2rgb(p, q, h + 1 / 3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1 / 3);
        }
        return { r: r * 255, g: g * 255, b: b * 255 };
    }

    function _toHex(r, g, b) {
        const h = n => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0");
        return "#" + h(r) + h(g) + h(b);
    }

    function _lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }

    function _buildAdaptive(rgbList) {
        const items = rgbList.map(c => {
            const hsl = root._rgbToHsl(c.r, c.g, c.b);
            return { r: c.r, g: c.g, b: c.b, h: hsl.h, s: hsl.s, l: hsl.l, lum: root._lum(c) };
        });
        items.sort((a, b) => a.lum - b.lum);

        let bg = { r: items[0].r, g: items[0].g, b: items[0].b };
        const bgLum = root._lum(bg);
        if (bgLum > 55) {
            const scale = 45 / Math.max(bgLum, 1);
            bg = { r: bg.r * scale, g: bg.g * scale, b: bg.b * scale };
        }

        const lightest = items[items.length - 1];
        let text = { r: lightest.r, g: lightest.g, b: lightest.b };
        const txLum = root._lum(text);
        if (txLum < 200) {
            const t = Math.min((235 - txLum) / Math.max(255 - txLum, 1), 0.85);
            text = {
                r: text.r + (255 - text.r) * t,
                g: text.g + (255 - text.g) * t,
                b: text.b + (255 - text.b) * t
            };
        }

        let vivid = items.filter(c => c.s > 0.18 && c.l > 0.2 && c.l < 0.85);
        // See bars/fullshell/Theme.qml: don't force 55%+ saturation onto
        // noise from a near-monochrome wallpaper -- that's what manufactures
        // an unrelated (often blue/violet) accent.
        const hasRealColor = vivid.length > 0;
        if (vivid.length === 0) vivid = items.slice();
        vivid = vivid.slice().sort((a, b) => b.s - a.s);
        const accentC = vivid[0];
        const accentS = hasRealColor ? Math.max(accentC.s, 0.55) : Math.min(accentC.s + 0.12, 0.3);
        const accentL = Math.min(Math.max(accentC.l, 0.45), 0.65);
        const accentRgb = root._hslToRgb(accentC.h, accentS, accentL);

        const surface = bgLum < 40
            ? { r: bg.r + 14, g: bg.g + 14, b: bg.b + 16 }
            : { r: bg.r * 1.15, g: bg.g * 1.15, b: bg.b * 1.15 };

        return {
            surface: root._toHex(surface.r, surface.g, surface.b),
            text: root._toHex(text.r, text.g, text.b),
            accent: root._toHex(accentRgb.r, accentRgb.g, accentRgb.b)
        };
    }

    readonly property var active: {
        if (_settings.adapter.themeMode === "light") return root.light;
        if (_settings.adapter.themeMode === "adaptive" && root.adaptivePalette) return root.adaptivePalette;
        return root.dark;
    }

    readonly property string surface: active.surface
    readonly property string foreground: active.text
    readonly property string accent: active.accent
    readonly property real barOpacity: _settings.adapter.barOpacity
}
