pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for every color, duration and easing in the bar.
// No component may hardcode a hex value or a duration -- they all read from
// here so a palette swap or a Config.reducedMotion flip is felt everywhere
// at once. Root-level singleton (not nested under config/) so every file in
// bar/, menus/ and widgets/ can reach it via a pure ".." ancestor-chain
// import -- a sideways import of a pragma-Singleton file silently returns
// an object whose every property is undefined in this Quickshell version
// (no error at all), so this file and Config.qml both stay at the tree
// root, one ".." away from every direct child folder.
QtObject {
    id: root

    // ---------------------------------------------------------------
    // Motion: durations & easings, the only place either is spelled out.
    // Config.reducedMotion collapses every duration to 0 from this one
    // spot -- nothing downstream needs its own reduced-motion branch.
    // ---------------------------------------------------------------
    readonly property bool reducedMotion: Config.reducedMotion
    readonly property string density: Config.density // "compact" | "normal"

    readonly property int durInstant: 0
    readonly property int durFast: reducedMotion ? 0 : 80 // click press/release
    readonly property int durBase: reducedMotion ? 0 : 180 // hover, digit roll
    readonly property int durSlow: reducedMotion ? 0 : 350 // popup open
    readonly property int durPalette: reducedMotion ? 0 : 400 // palette crossfade
    readonly property int durBoot: reducedMotion ? 0 : 1150 // self-test sequence
    readonly property int durIdle: reducedMotion ? 0 : 6000 // idle bevel glint cycle
    readonly property int idleGlintInterval: reducedMotion ? 0 : 45000 // gap between idle glint sweeps
    readonly property int staggerStep: reducedMotion ? 0 : 25 // per-segment fill offset

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeOutBack: Easing.OutBack
    readonly property int easeInOut: Easing.InOutQuad
    readonly property int easeLinear: Easing.Linear

    // ---------------------------------------------------------------
    // Layout
    // ---------------------------------------------------------------
    readonly property int barHeight: density === "compact" ? 30 : 38
    readonly property int radius: 4
    readonly property int gap: density === "compact" ? 6 : 9
    readonly property int bevelWidth: 1

    // ---------------------------------------------------------------
    // External palette: matugen / wallust / pywal. pywal's colors.json is
    // what's actually present on this system (~/.cache/wal/colors.json,
    // written by `wal`/shellwall on every wallpaper change) -- watched
    // live so a wallpaper swap re-colors the bar without a restart.
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

    // Seed used only when no external generator has ever produced a
    // palette file -- a full HSL-derived scheme grown from one color. This
    // is an HSL approximation of a Material-style tone/chroma ramp, not
    // real perceptual HCT/CAM16 -- implementing the latter in JS was judged
    // not worth it for a fallback path that this system's pywal output
    // means we never actually hit.
    readonly property color _seed: "#5b8cff"
    readonly property var _seedPalette: _deriveFromSeed(_seed)

    function _deriveFromSeed(seed) {
        const hsl = _rgbToHsl(seed);
        return {
            surface: _hslColor(hsl.h, 0.14, 0.14),
            ink: _hslColor(hsl.h, 0.06, 0.92),
            accent: _hslColor(hsl.h, Math.min(hsl.s + 0.25, 0.85), 0.56)
        };
    }

    readonly property color _rawSurface: _hasExternalPalette ? _paletteData.special.background : _seedPalette.surface
    readonly property color _rawInk: _hasExternalPalette ? _paletteData.special.foreground : _seedPalette.ink
    readonly property color _rawAccent: _hasExternalPalette ? _paletteData.colors.color4 : _seedPalette.accent

    readonly property bool isDark: _luminance(_rawSurface) < 0.5

    // ---------------------------------------------------------------
    // Semantic roles -- the only colors any component may reference.
    // Not `readonly`: each carries a Behavior below so a palette swap
    // (new _rawX from the file watcher) crossfades over durPalette
    // instead of snapping, and this QML engine rejects a Behavior on a
    // readonly property outright ("is a read-only property"). Nothing
    // outside this file assigns to them; that's a convention, not
    // something QML enforces here.
    //
    // Named surfaceInk/accentInk rather than the Material onSurface/
    // onAccent spelling: a QML property whose name matches /^on[A-Z]/ is
    // indistinguishable from a signal-handler slot to this engine's
    // Behavior wiring and reproducibly segfaults the process on load --
    // confirmed by isolated bisection (a lone `Behavior on onSurface`
    // crashes by itself; renaming it is what fixed it). Not a QML rule in
    // general, just how this Quickshell/Qt build behaves -- avoid the
    // on+Capital prefix for any property that carries a Behavior.
    // ---------------------------------------------------------------
    property color surface: _rawSurface
    property color surfaceDim: _mix(_rawSurface, "black", 0.18)
    property color surfaceInk: _rawInk
    property color accent: _rawAccent
    property color accentInk: _contrastOn(_rawAccent)

    property color critical: _tintedSemantic(6)
    property color warning: _tintedSemantic(42)
    property color success: _tintedSemantic(140)

    // Bevel edges are derived from surface by moving a fixed *fraction of
    // the remaining headroom* toward white/black, not by a fixed delta.
    // That's what makes the "recognizes light vs. dark and flips" ask in
    // the spec fall out automatically: on a dark surface there's lots of
    // headroom to white and little to black, so bevelLight carries the
    // contrast; on a light surface it inverts on its own, no branch
    // needed. Silver on a neutral palette, brass on a warm one, for the
    // same reason -- it's just surface's own hue carried through.
    property color bevelLight: _desaturate(_mix(_rawSurface, "white", 0.55), 0.35)
    property color bevelDark: _mix(_rawSurface, "black", 0.55)

    property color glassTint: Qt.rgba(1, 1, 1, isDark ? 0.05 : 0.35)

    readonly property var _segHsl: _rgbToHsl(_rawAccent)
    readonly property real _segSat: Math.min(_segHsl.s + 0.15, 0.9)
    readonly property real _segLight: isDark ? 0.62 : 0.4
    property color segmentOn: _hslColor(_segHsl.h, _segSat, _segLight)
    property color segmentOff: Qt.rgba(_segRgb.r, _segRgb.g, _segRgb.b, 0.08)
    readonly property color _segRgb: _hslColor(_segHsl.h, _segSat, _segLight)

    // ---------------------------------------------------------------
    // Color math -- plain RGB/HSL JS, no dependency on QML color's
    // hsl* accessors (version-sensitive; this is self-contained instead).
    // ---------------------------------------------------------------
    function _luminance(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    function _mix(a, b, t) {
        const ca = Qt.color(a), cb = Qt.color(b);
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, ca.a + (cb.a - ca.a) * t);
    }

    function _desaturate(c, amt) {
        const l = _luminance(c);
        return _mix(c, Qt.rgba(l, l, l, c.a), amt);
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

    // Fixed hue targets (red/amber/green) but saturation & lightness are
    // pulled from the live surface tone, so status colors still feel like
    // they belong to the current palette instead of being stock traffic
    // lights slapped on top of it.
    function _tintedSemantic(hueDeg) {
        const base = _rgbToHsl(_rawSurface);
        const s = Math.max(0.45, Math.min(base.s + 0.35, 0.75));
        const l = isDark ? 0.58 : 0.44;
        return _hslColor(hueDeg / 360, s, l);
    }

    function _contrastOn(c) {
        return _luminance(c) > 0.6 ? Qt.rgba(0.08, 0.08, 0.1, 1) : Qt.rgba(0.96, 0.96, 0.98, 1);
    }

    // Crossfade every role over a palette change instead of snapping.
    Behavior on surface {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on surfaceDim {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on surfaceInk {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on accent {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on accentInk {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on critical {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on warning {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on success {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bevelLight {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bevelDark {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on glassTint {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on segmentOn {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on segmentOff {
        enabled: !root.reducedMotion
        ColorAnimation {
            duration: root.durPalette
            easing.type: Easing.InOutQuad
        }
    }
}
