pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for every color/duration/easing in this bar.
// Root-level singleton (not nested in a subfolder) so every file anywhere
// in this tree reaches it via a pure ".." ancestor-chain import -- a
// sideways/symlinked import of a pragma-Singleton silently yields an
// object whose every property is undefined in this Quickshell version, no
// error at all (confirmed in bars/fisheye). Pattern below (pywal palette +
// HSL-derived semantic roles + per-role Behavior crossfade) is copied from
// bars/fisheye/Theme.qml, which is already verified against this system.
QtObject {
    id: root

    readonly property int durFast: 120
    readonly property int durBase: 260
    readonly property int durNeedle: 400 // gauge/compass needle sweep
    readonly property int durMorph: 320 // clock-module grow/shrink, launcher slide-in
    readonly property int durPalette: 400
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeOutBack: Easing.OutBack
    readonly property int easeInOut: Easing.InOutQuad

    readonly property int barHeight: 44
    readonly property int panelRadius: 10
    readonly property int rivetSize: 4

    // ---------------------------------------------------------------
    // External palette: pywal's colors.json, watched live.
    // ---------------------------------------------------------------
    property var _paletteData: null
    readonly property bool _hasExternalPalette: _paletteData !== null

    property FileView _paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        printErrors: false
        watchChanges: true
        onLoaded: root._parsePalette(text())
        onLoadFailed: error => {
            root._paletteData = null;
        }
        onFileChanged: reload()
    }

    function _parsePalette(text) {
        try {
            root._paletteData = JSON.parse(text);
        } catch (e) {
            root._paletteData = null;
        }
    }

    // Warm brass seed for the no-pywal fallback -- distinct from fisheye's
    // cool blue seed, matches this bar's metal-panel identity.
    readonly property color _seed: "#b8863a"
    readonly property var _seedPalette: _deriveFromSeed(_seed)

    function _deriveFromSeed(seed) {
        const hsl = _rgbToHsl(seed);
        return {
            surface: _hslColor(hsl.h, 0.35, 0.22),
            ink: _hslColor(hsl.h, 0.08, 0.92),
            accent: _hslColor(hsl.h, Math.min(hsl.s + 0.2, 0.7), 0.55)
        };
    }

    readonly property color _rawSurface: _hasExternalPalette ? _paletteData.special.background : _seedPalette.surface
    readonly property color _rawInk: _hasExternalPalette ? _paletteData.special.foreground : _seedPalette.ink
    readonly property color _rawAccent: _hasExternalPalette ? _paletteData.colors.color3 : _seedPalette.accent

    readonly property bool isDark: _luminance(_rawSurface) < 0.5

    // ---------------------------------------------------------------
    // Semantic roles. Not `readonly` -- each has a Behavior below for a
    // soft crossfade on palette change instead of a snap; this engine
    // rejects a Behavior on a readonly property outright. Named *Ink
    // rather than on* -- a QML property matching /^on[A-Z]/ that carries a
    // Behavior reproducibly segfaults this Quickshell build on load (see
    // bars/fisheye/Theme.qml for the isolated repro).
    // ---------------------------------------------------------------
    property color panelMetal: _mix(_rawSurface, "#3a2f1f", 0.35) // brushed-brass base
    property color panelMetalDim: _mix(panelMetal, "black", 0.22)
    property color panelInk: _rawInk

    property color dialFace: _mix(_rawSurface, "black", 0.45) // instrument face, darker than the panel
    property color dialRim: _mix(_rawSurface, "white", 0.12)
    property color needleColor: _tintedSemantic(6)
    property color needleHub: _mix(needleColor, "black", 0.3)

    property color accent: _rawAccent
    property color accentInk: _contrastOn(_rawAccent)

    property color zoneGood: _tintedSemantic(140)
    property color zoneWarn: _tintedSemantic(42)
    property color zoneCritical: _tintedSemantic(6)

    property color lampOff: _mix(_rawSurface, "black", 0.5)
    property color lampOn: _tintedSemantic(42)

    // Bevel: fixed fraction of headroom toward white/black, flips
    // automatically between light and dark palettes without a branch --
    // same technique as bars/fisheye/Theme.qml.
    property color rivetLight: _mix(panelMetal, "white", 0.5)
    property color rivetDark: _mix(panelMetal, "black", 0.55)
    property color dividerLine: _mix(panelMetal, "black", 0.6)

    // ---------------------------------------------------------------
    // Color math -- plain RGB/HSL JS (version-independent).
    // ---------------------------------------------------------------
    function _luminance(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    function _mix(a, b, t) {
        const ca = Qt.color(a), cb = Qt.color(b);
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, ca.a + (cb.a - ca.a) * t);
    }

    function _rgbToHsl(c) {
        const col = Qt.color(c);
        const r = col.r, g = col.g, b = col.b;
        const max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h = 0, s = 0;
        const l = (max + min) / 2;
        const d = max - min;
        if (d > 0) {
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
            case r:
                h = (g - b) / d + (g < b ? 6 : 0);
                break;
            case g:
                h = (b - r) / d + 2;
                break;
            default:
                h = (r - g) / d + 4;
                break;
            }
            h /= 6;
        }
        return {
            h: h,
            s: s,
            l: l
        };
    }

    function _hslColor(h, s, l) {
        function hue2rgb(p, q, t) {
            if (t < 0)
                t += 1;
            if (t > 1)
                t -= 1;
            if (t < 1 / 6)
                return p + (q - p) * 6 * t;
            if (t < 1 / 2)
                return q;
            if (t < 2 / 3)
                return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        }
        if (s === 0)
            return Qt.rgba(l, l, l, 1);
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        return Qt.rgba(hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3), 1);
    }

    function _tintedSemantic(hueDeg) {
        const base = _rgbToHsl(_rawSurface);
        const s = Math.max(0.5, Math.min(base.s + 0.35, 0.8));
        const l = isDark ? 0.58 : 0.44;
        return _hslColor(hueDeg / 360, s, l);
    }

    function _contrastOn(c) {
        return _luminance(c) > 0.6 ? Qt.rgba(0.08, 0.08, 0.1, 1) : Qt.rgba(0.96, 0.96, 0.98, 1);
    }

    Behavior on panelMetal {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on panelMetalDim {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on panelInk {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on dialFace {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on dialRim {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on accent {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on accentInk {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on rivetLight {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on rivetDark {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on dividerLine {
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
}
