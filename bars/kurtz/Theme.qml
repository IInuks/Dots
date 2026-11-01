pragma Singleton
import QtQuick
import Quickshell

// The single source of every color, radius, spacing, duration and font in
// kurtz. Components never hardcode a value -- they ask Theme.
//
// LIGHT SOURCE: always upper-left. Every shaded object (see
// components/Orb.qml) puts its highlight up-left and its shadow crescent
// down-right; keep it that way when adding new shapes.
Singleton {
    id: root

    readonly property var c: Config.s

    // ---------------------------------------------------------------- sky
    // Background gradients ("far" depth layer). top -> mid -> bottom.
    // "wallpaper" is built from the wallpaper's hues (see Wallpaper.qml),
    // pulled towards blue-violet so warm images give a sunset-ish night,
    // never a brown one. Until matugen has answered it shows nebula.
    readonly property var skies: ({
            nebula: ["#0B0F2F", "#14164A", "#2B1B6B"],
            deepsea: ["#04122B", "#0A2350", "#0F3B70"],
            sunset: ["#170C36", "#35124F", "#6A1D5E"],
            aurora: ["#051726", "#0A2B3C", "#11494A"],
            void: ["#07081C", "#0C0E2A", "#15173D"],
            wallpaper: Wallpaper.ready ? [
                Qt.hsla(_wpHueA, 0.62, 0.10, 1),
                Qt.hsla(_hueLerp(_wpHueA, _wpHueB, 0.45), 0.58, 0.17, 1),
                Qt.hsla(_wpHueB, 0.58, 0.25, 1)
            ] : ["#0B0F2F", "#14164A", "#2B1B6B"]
        })
    readonly property var skyNames: ["nebula", "deepsea", "sunset", "aurora", "void", "wallpaper"]
    readonly property var _sky: skies[c.sky] || skies.nebula
    readonly property color bgTop: _sky[0]
    readonly property color bgMid: _sky[1]
    readonly property color bgBottom: _sky[2]

    readonly property real _wpHueA: _towardsNight(_hueOf(Wallpaper.primary))
    readonly property real _wpHueB: _towardsNight(_hueOf(Wallpaper.secondary))
    function _hueOf(col) {
        return col.hslHue < 0 ? 0.68 : col.hslHue;
    }
    // Shortest way round the hue circle.
    function _hueLerp(a, b, t) {
        let d = b - a;
        if (d > 0.5) d -= 1;
        if (d < -0.5) d += 1;
        return (a + d * t + 1) % 1;
    }
    function _towardsNight(h) {
        return _hueLerp(h, 0.70, 0.2);
    }

    // --------------------------------------------------------- surfaces
    // "Mid" depth layer: cards, pills, rows. Fixed indigo, or with the
    // wallpaper sky the same lightness steps in the sky's hue.
    readonly property bool _wpSky: c.sky === "wallpaper" && Wallpaper.ready
    readonly property real _surfHue: _hueLerp(_wpHueA, _wpHueB, 0.45)
    readonly property color surface: _wpSky ? Qt.hsla(_surfHue, 0.54, 0.23, 1) : "#1B1E5A"
    readonly property color surfaceRaised: _wpSky ? Qt.hsla(_surfHue, 0.50, 0.30, 1) : "#262A73"
    readonly property color surfaceHover: _wpSky ? Qt.hsla(_surfHue, 0.49, 0.38, 1) : "#313690"
    readonly property color surfaceSunken: _wpSky ? Qt.hsla(_surfHue, 0.56, 0.16, 1) : "#12143F"

    // ----------------------------------------------------------- accents
    readonly property var accents: ({
            cyan: "#38BDF8",
            blue: "#3B82F6",
            purple: "#A855F7",
            magenta: "#E879F9",
            orange: "#FB923C",
            yellow: "#FACC15",
            red: "#F43F5E",
            green: "#34D399"
        })
    readonly property var accentNames: ["cyan", "blue", "purple", "magenta", "orange", "yellow", "red", "green"]
    readonly property color cyan: accents.cyan
    readonly property color blue: accents.blue
    readonly property color purple: accents.purple
    readonly property color magenta: accents.magenta
    readonly property color orange: accents.orange
    readonly property color yellow: accents.yellow
    readonly property color red: accents.red
    readonly property color green: accents.green

    // Accent derived from the wallpaper: matugen's hue, but at full
    // Kurzgesagt brightness instead of Material's pastel.
    function _vivid(col) {
        return Qt.hsla(_hueOf(col), Math.max(0.78, col.hslSaturation), 0.62, 1);
    }
    readonly property bool _wpAccent: c.accent === "wallpaper" && Wallpaper.ready
    // Studio swatches: the named accents plus "wallpaper".
    readonly property var accentChoices: accentNames.concat(["wallpaper"])
    function accentColor(name) {
        if (name === "wallpaper")
            return Wallpaper.ready ? _vivid(Wallpaper.primary) : accents.cyan;
        return accents[name] || accents.cyan;
    }

    // User-chosen primary accent ("default/active" semantic slot).
    readonly property color accent: _wpAccent ? _vivid(Wallpaper.primary) : (accents[c.accent] || accents.cyan)
    // A second hue that always harmonises with the accent, for gradients.
    readonly property color accent2: {
        if (_wpAccent)
            return _vivid(Wallpaper.tertiary);
        const pairs = { cyan: "blue", blue: "purple", purple: "magenta", magenta: "purple",
                        orange: "yellow", yellow: "orange", red: "magenta", green: "cyan" };
        return accents[pairs[c.accent] || "blue"];
    }

    // Semantic mapping (style guide section 3).
    readonly property color ok: green
    readonly property color warn: yellow
    readonly property color energy: orange
    readonly property color crit: red
    readonly property color media: purple

    // -------------------------------------------------------------- text
    readonly property color text: "#F5F3FF"
    readonly property color textMuted: "#94A3B8"
    readonly property color textFaint: "#5B6488"

    // ------------------------------------------------------ shading math
    // Shadow tone: darker, a bit more saturated and hue-shifted towards
    // blue/purple (Kurzgesagt shadows are never grey).
    function shadeOf(col) {
        const h = col.hslHue < 0 ? 0.68 : col.hslHue;
        const target = 0.70; // blue-violet
        let d = target - h;
        if (d > 0.5) d -= 1;
        if (d < -0.5) d += 1;
        const nh = (h + d * 0.18 + 1) % 1;
        return Qt.hsla(nh, Math.min(1, col.hslSaturation * 1.12 + 0.05), col.hslLightness * 0.58, col.a);
    }
    // Highlight tone: lighter, slightly warm, slightly desaturated.
    function highlightOf(col) {
        const h = col.hslHue < 0 ? 0 : col.hslHue;
        return Qt.hsla(h, col.hslSaturation * 0.85, col.hslLightness + (1 - col.hslLightness) * 0.55, col.a);
    }
    // Rim light: thin bright edge on the shadow side.
    function rimOf(col) {
        const h = col.hslHue < 0 ? 0 : col.hslHue;
        return Qt.hsla(h, Math.min(1, col.hslSaturation * 1.1), Math.min(0.9, col.hslLightness * 1.25 + 0.1), 0.85);
    }
    function alpha(col, a) {
        return Qt.rgba(col.r, col.g, col.b, a);
    }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    // green -> yellow -> red for "how full is this" values (0..1).
    function levelColor(v) {
        return v < 0.6 ? root.accent : v < 0.85 ? root.warn : root.crit;
    }

    // ------------------------------------------------------------ geometry
    readonly property real rs: c.radiusScale
    readonly property int rSmall: Math.round(12 * rs)
    readonly property int rMed: Math.round(18 * rs)
    readonly property int rLarge: Math.round(26 * rs)

    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 24
    readonly property int s6: 32

    readonly property int barHeight: c.barHeight
    readonly property int barMargin: c.barMargin
    readonly property bool barTop: c.barPosition !== "bottom"
    readonly property bool islands: c.barStyle === "islands"
    readonly property int pillHeight: Math.round(barHeight - 12)
    readonly property int popupGap: 12

    // -------------------------------------------------------------- depth
    readonly property real glow: c.glow
    readonly property bool grain: c.grain
    readonly property real grainOpacity: 0.045
    readonly property bool stars: c.stars
    readonly property bool twinkle: c.twinkle && animations
    readonly property color shadowColor: "#03041A"

    // ------------------------------------------------------------- motion
    readonly property bool animations: c.animations
    readonly property real _k: animations ? c.animSpeed : 0
    readonly property int tFast: Math.round(180 * _k)
    readonly property int tMed: Math.round(260 * _k)
    readonly property int tSlow: Math.round(320 * _k)
    readonly property int tPop: Math.round(420 * _k)
    readonly property int easeOut: Easing.OutCubic
    readonly property int easePop: Easing.OutBack
    readonly property real popOvershoot: 1.35
    readonly property real hoverScale: 1.04
    readonly property real pressScale: 0.96

    // Locale for day/month names (Config "locale").
    readonly property var locale: Qt.locale(c.locale)
    function date(d, fmt) {
        return d.toLocaleDateString(root.locale, fmt);
    }

    // -------------------------------------------------------------- fonts
    // Qt has no CSS-like fallback list, so the stack is resolved once
    // against the installed families.
    readonly property var _families: Qt.fontFamilies()
    function _pick(list) {
        for (const f of list)
            if (_families.indexOf(f) >= 0)
                return f;
        return "sans-serif";
    }
    readonly property string font: _pick(["Poppins", "Montserrat", "Sofia Pro", "Inter", "Adwaita Sans", "Noto Sans", "DejaVu Sans"])
    readonly property string iconFont: _pick(["JetBrainsMono Nerd Font Propo", "Symbols Nerd Font", "JetBrainsMono Nerd Font"])
    readonly property real fs: c.fontScale
    readonly property int fTiny: Math.round(9 * fs)
    readonly property int fSmall: Math.round(11 * fs)
    readonly property int fBody: Math.round(13 * fs)
    readonly property int fTitle: Math.round(16 * fs)
    readonly property int fBig: Math.round(22 * fs)
    readonly property int fHuge: Math.round(48 * fs)
}
