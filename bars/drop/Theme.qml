pragma Singleton
import QtQuick
import Quickshell

// Die Palette des Wassers. Im Modus "wallpaper" wird sie aus Wall.colors
// abgeleitet (wie in eierschale):
//   Akzent  = der bunteste Kandidat, auf lesbare Helligkeit gezogen
//   Akzent2 = der Kandidat mit dem größten Farbtonabstand
//   Grund   = Farbton der dunkelsten Farbe, sehr dunkel ("Tiefe")
// Farbwechsel gleiten über einen Mischfaktor _t (kein Behavior: das
// crasht Quickshell 0.3.1 in Singletons).
Singleton {
    id: root

    // ---------------------------------------------------------- Presets
    readonly property var presets: ({
        tiefsee: { base: "#06131d", accent: "#4fd1e8", accent2: "#8aa4ff", text: "#e4f6ff" },
        lagune:  { base: "#05201b", accent: "#5eead4", accent2: "#ffbe7a", text: "#e8fff9" },
        regen:   { base: "#11151c", accent: "#9db8d6", accent2: "#7dd3fc", text: "#eef3f8" },
        tinte:   { base: "#0f0b1c", accent: "#a991ff", accent2: "#f58ac4", text: "#f3efff" }
    })
    readonly property var presetNames: ["tiefsee", "lagune", "regen", "tinte"]
    readonly property var presetLabels: ({ tiefsee: "Tiefsee", lagune: "Lagune", regen: "Regen", tinte: "Tinte" })

    // ------------------------------------------------------- Ableitung
    function _hsl(c) { return { h: c.hslHue < 0 ? 0 : c.hslHue, s: c.hslSaturation, l: c.hslLightness }; }
    function _hueDist(a, b) { const d = Math.abs(a - b) % 1; return Math.min(d, 1 - d); }
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    // Kandidaten nach Buntheit, ohne Fast-Doppelte. Auch fürs Labor-Menü.
    readonly property var candidates: {
        const cs = Wall.colors || [];
        const out = [];
        for (let i = 0; i < cs.length; i++)
            out.push({ c: cs[i], score: cs[i].hsvSaturation * (0.35 + cs[i].hsvValue) });
        out.sort((a, b) => b.score - a.score);
        const uniq = [];
        for (const o of out) {
            if (!uniq.some(u => _hueDist(u.c.hslHue, o.c.hslHue) < 0.03 && Math.abs(u.c.hslLightness - o.c.hslLightness) < 0.12))
                uniq.push(o);
        }
        return uniq.slice(0, 8).map(o => String(root._lift(o.c)));
    }

    function _lift(c) {
        const h = _hsl(c);
        return Qt.hsla(h.h, _clamp(Math.max(h.s, 0.5), 0, 0.9), _clamp(h.l, 0.62, 0.74), 1);
    }

    readonly property var _derived: {
        const cs = Wall.colors || [];
        if (cs.length === 0 || candidates.length === 0)
            return presets.tiefsee;
        const pick = Settings.data.accentPick;
        const acc = Qt.color(candidates[pick >= 0 && pick < candidates.length ? pick : 0]);
        const ah = acc.hslHue < 0 ? 0 : acc.hslHue;

        let acc2 = null, best = 0;
        for (const s of candidates) {
            const c = Qt.color(s);
            const d = _hueDist(c.hslHue, ah);
            if (d > best && d > 0.12) { best = d; acc2 = c; }
        }
        if (!acc2)
            acc2 = Qt.hsla((ah + 0.42) % 1, 0.62, 0.7, 1);

        let dark = cs[0];
        for (const c of cs) if (c.hslLightness < dark.hslLightness) dark = c;
        const dh = _hsl(dark);
        const baseHue = dh.s > 0.08 ? dh.h : ah;
        return {
            base: String(Qt.hsla(baseHue, _clamp(dh.s, 0.22, 0.45), 0.075, 1)),
            accent: String(acc),
            accent2: String(acc2),
            text: String(Qt.hsla(baseHue, 0.35, 0.94, 1))
        };
    }

    readonly property var _target: Settings.data.themeMode === "wallpaper" ? _derived : (presets[Settings.data.themeMode] || presets.tiefsee)

    // ------------------------------------------------------- Überblenden
    property var _from: presets.tiefsee
    property var _to: presets.tiefsee
    property real _t: 1
    property bool _first: true
    on_TargetChanged: {
        const t = _target;
        if (_first) { _first = false; _from = t; _to = t; _t = 1; return; }
        _from = { base: String(base), accent: String(accent), accent2: String(accent2), text: String(text) };
        _to = t;
        _t = 0;
        fade.restart();
    }
    NumberAnimation { id: fade; target: root; property: "_t"; from: 0; to: 1; duration: 900; easing.type: Easing.InOutQuad }
    Component.onCompleted: { _from = _target; _to = _target; _first = false; }

    function mix(a, b, t) {
        const x = Qt.color(a), y = Qt.color(b);
        return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, x.a + (y.a - x.a) * t);
    }
    function alpha(c, a) { const x = Qt.color(c); return Qt.rgba(x.r, x.g, x.b, a); }
    function _shift(c, dl, ds) {
        const x = Qt.color(c);
        const h = _hsl(x);
        return Qt.hsla(h.h, _clamp(h.s + (ds || 0), 0, 1), _clamp(h.l + dl, 0, 1), 1);
    }

    // ------------------------------------------------------- Rollen
    readonly property color base: mix(_from.base, _to.base, _t)
    readonly property color accent: mix(_from.accent, _to.accent, _t)
    readonly property color accent2: mix(_from.accent2, _to.accent2, _t)
    readonly property color text: mix(_from.text, _to.text, _t)

    readonly property color surface: _shift(base, 0.05, 0)
    readonly property color surface2: _shift(base, 0.10, -0.04)
    readonly property color surface3: _shift(base, 0.17, -0.08)
    // Wasser = der Körper der Leiste und der Tropfen-Menüs
    readonly property color water: mix(base, accent, 0.05)
    readonly property color waterDeep: mix(base, accent, 0.16)
    readonly property color textDim: alpha(text, 0.62)
    readonly property color textFaint: alpha(text, 0.32)
    readonly property color accentInk: base          // Schrift auf Akzent ("on*" geht nicht als Name)
    readonly property color line: alpha(text, 0.09)
    readonly property color glint: alpha(mix(accent, "#ffffff", 0.5), 0.35)   // Lichtkante am Wasser
    readonly property color good: "#7ee0b3"
    readonly property color warn: "#ffc56b"
    readonly property color bad: "#ff7a85"

    // ------------------------------------------------------- Export
    // Aufgelöste Palette nach ~/.local/state/drop/palette.json, damit das
    // quickdots-Menü (adapters/live/DropLive.qml) mitfärben kann.
    readonly property string _exportJson: JSON.stringify({
        surface: _target.base, foreground: _target.text, accent: _target.accent,
        accent2: _target.accent2, barOpacity: Settings.data.opacity
    })
    on_ExportJsonChanged: exportT.restart()
    Timer {
        id: exportT
        interval: 800
        onTriggered: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && printf %s "$2" > "$1/palette.json"',
            "sh", Quickshell.env("HOME") + "/.local/state/drop", root._exportJson])
    }

    // ------------------------------------------------------- Maße
    readonly property string font: "Adwaita Sans"
    readonly property string round: "Quicksand"     // Uhr, Überschriften: weich wie Wasser
    readonly property string mono: "JetBrainsMono Nerd Font Propo"
    readonly property string icons: "JetBrainsMono Nerd Font Propo"

    readonly property int film: Settings.data.film ? 5 : 0   // der durchgehende Wasserfilm oben
    readonly property int beadH: 36                          // Höhe der hängenden Perlen
    readonly property int beadR: 14
    readonly property int barH: beadH + 6                    // Fensterhöhe der Leiste
    readonly property int neck: 16                           // Abstand Perle -> Tropfen-Menü
    readonly property int radius: 22
    readonly property int pad: 14

    // ------------------------------------------------------- Bewegung
    readonly property real speed: Settings.data.animSpeed
    readonly property bool motion: speed > 0
    function ms(v) { return Math.max(1, Math.round(v * speed)); }
    readonly property int tFast: ms(140)
    readonly property int tMed: ms(260)
    readonly property int tSlow: ms(480)
    readonly property int tDrip: ms(520)
}
