pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Central palette + geometry singleton. "adaptive" extracts real dominant
// colors from the current wallpaper via ImageMagick (same technique as
// bars/quickbar/Theme.qml) -- kept as its own copy per this repo's
// convention of bar singletons never importing each other.
QtObject {
    id: root

    readonly property string mode: Settings.themeMode
    function setMode(m) { Settings.setThemeMode(m); }

    property bool settingsReady: Settings.loaded
    onSettingsReadyChanged: if (settingsReady) enableCrossfade()

    // "Aurora": violet/pink neon-on-ink, distinct from the other bars'
    // teal/mono/blue identities.
    readonly property var dark: ({
        bg: "#0d0b1a",
        surface: "#17142a",
        surfaceAlt: "#211c38",
        text: "#eae6ff",
        textDim: "#8f89ac",
        accent: "#7c5cff",
        accent2: "#ff5cb8",
        danger: "#ff5c7a",
        warn: "#ffb454",
        success: "#59e6a8"
    })

    readonly property var light: ({
        bg: "#f3f0fb",
        surface: "#ffffff",
        surfaceAlt: "#ece7fb",
        text: "#201a35",
        textDim: "#6a6280",
        accent: "#6b3fe0",
        accent2: "#d6318f",
        danger: "#d6314f",
        warn: "#b8720a",
        success: "#1f9d63"
    })

    property var adaptivePalette: null
    property string _lastExtractedPath: ""

    property string wallpaperSetting: Settings.wallpaperPath
    onWallpaperSettingChanged: if (wallpaperSetting) root._extractFromWallpaper(wallpaperSetting)
    Component.onCompleted: if (wallpaperSetting) root._extractFromWallpaper(wallpaperSetting)

    property Process _extractProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root._onExtractOutput(text)
        }
    }
    property string _pendingExtractPath: ""

    // Reassigning `command` while a previous extraction is still running
    // does NOT restart it with the new path (running was already true, so
    // that property write is a no-op) -- the border/glow would then
    // silently keep whatever accent an earlier wallpaper produced (or the
    // dark-palette fallback if none has ever finished yet) no matter what
    // the user picks next. Stopping and deferring the restart to the next
    // event-loop turn (rather than flipping running false->true in the
    // same call) gives the old process a tick to actually tear down first.
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
        else root._lastExtractedPath = ""; // let a retry happen instead of getting stuck
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
        // Whether the wallpaper has any real color signal at all. A moody
        // / overcast / near-monochrome photo can fail to clear the vivid
        // threshold entirely, but `vivid[0]` still ends up as *some*
        // pixel -- and hue is numerically unstable for near-gray colors,
        // so forcing that noise up to 55% saturation manufactures a
        // random, often blue/violet accent that has nothing to do with
        // the actual image (this is the "purple border doesn't match"
        // failure mode).
        const hasRealColor = vivid.length > 0;
        if (vivid.length === 0) vivid = items.slice();
        vivid = vivid.slice().sort((a, b) => b.s - a.s);
        const accentC = vivid[0];
        const accentS = hasRealColor ? Math.max(accentC.s, 0.55) : Math.min(accentC.s + 0.12, 0.3);
        const accentL = Math.min(Math.max(accentC.l, 0.45), 0.65);
        const accentRgb = root._hslToRgb(accentC.h, accentS, accentL);

        const accent2C = vivid.find(c => {
            const dh = Math.abs(((c.h - accentC.h + 540) % 360) - 180);
            return dh < 150 && c !== accentC;
        });
        const accent2Hue = accent2C ? accent2C.h : (accentC.h + 40) % 360;
        const accent2S = hasRealColor ? Math.max(accentS - 0.05, 0.4) : accentS;
        const accent2Rgb = root._hslToRgb(accent2Hue, accent2S, Math.min(accentL + 0.05, 0.7));

        const surface = bgLum < 40
            ? { r: bg.r + 14, g: bg.g + 14, b: bg.b + 16 }
            : { r: bg.r * 1.15, g: bg.g * 1.15, b: bg.b * 1.15 };
        const surfaceAlt = { r: surface.r + 10, g: surface.g + 10, b: surface.b + 12 };
        const textDim = { r: text.r * 0.62 + bg.r * 0.12, g: text.g * 0.62 + bg.g * 0.12, b: text.b * 0.62 + bg.b * 0.12 };

        return {
            bg: root._toHex(bg.r, bg.g, bg.b),
            surface: root._toHex(surface.r, surface.g, surface.b),
            surfaceAlt: root._toHex(surfaceAlt.r, surfaceAlt.g, surfaceAlt.b),
            text: root._toHex(text.r, text.g, text.b),
            textDim: root._toHex(textDim.r, textDim.g, textDim.b),
            accent: root._toHex(accentRgb.r, accentRgb.g, accentRgb.b),
            accent2: root._toHex(accent2Rgb.r, accent2Rgb.g, accent2Rgb.b),
            danger: "#ff5c7a",
            warn: "#ffb454",
            success: "#59e6a8"
        };
    }

    readonly property var active: {
        if (root.mode === "light") return root.light;
        if (root.mode === "adaptive" && root.adaptivePalette) return root.adaptivePalette;
        return root.dark;
    }

    property color bg: active.bg
    property color surface: active.surface
    property color surfaceAlt: active.surfaceAlt
    property color text: active.text
    property color textDim: active.textDim
    property color accent: active.accent
    property color accent2: active.accent2
    property color danger: active.danger
    property color warn: active.warn
    property color success: active.success

    property bool _crossfade: false

    Behavior on bg { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on surface { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on surfaceAlt { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on text { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on textDim { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on accent { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on accent2 { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on danger { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on warn { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }
    Behavior on success { enabled: root._crossfade; ColorAnimation { duration: root.animSlow } }

    function enableCrossfade() { root._crossfade = true; }

    // Transparency: 0.35 (very see-through) .. 1.0 (opaque), user-tunable
    // in the Design tab. Multiplies every surface's alpha.
    readonly property real barAlpha: Settings.barOpacity

    property int radiusSmall: 8
    property int radiusMed: 16
    property int radiusPill: 22
    property int animFast: 150
    property int animMed: 280
    property int animSlow: 480
}
