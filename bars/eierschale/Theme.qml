pragma Singleton
import QtQuick
import Quickshell

// Die Palette. Im Modus "wallpaper" wird sie aus Wall.colors abgeleitet:
//   Akzent  = der Kandidat mit der meisten Farbe (Sättigung x Helligkeit),
//             auf gut lesbare Helligkeit gezogen
//   Akzent2 = der Kandidat, dessen Farbton am weitesten vom Akzent weg ist
//             (sonst Akzent um 150° gedreht)
//   Grund   = Farbton der dunkelsten Farbe, sehr dunkel, leicht gesättigt
// Jede Farbe gleitet beim Wechsel sanft über (ColorAnimation), so dass ein
// neues Wallpaper die ganze Shell "umfärbt" statt umzuspringen.
Singleton {
    id: root

    // ---------------------------------------------------------- Presets
    readonly property var presets: ({
        schoko:      { base: "#1f140f", accent: "#ff7a1a", accent2: "#e8384f", text: "#fff3e6" },
        ostern:      { base: "#1b1a24", accent: "#f7a8c9", accent2: "#9fe0c1", text: "#fbf6ff" },
        mitternacht: { base: "#0d1020", accent: "#7aa2ff", accent2: "#ffcf5c", text: "#eef1ff" },
        minze:       { base: "#0f1a18", accent: "#6ee7b7", accent2: "#f9a8d4", text: "#effff9" }
    })
    readonly property var presetNames: ["schoko", "ostern", "mitternacht", "minze"]

    // ------------------------------------------------------- Ableitung
    function _hsl(c) { return { h: c.hslHue < 0 ? 0 : c.hslHue, s: c.hslSaturation, l: c.hslLightness }; }
    function _hueDist(a, b) { const d = Math.abs(a - b) % 1; return Math.min(d, 1 - d); }
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    // Kandidaten nach "Buntheit" sortiert -- auch für die Akzent-Auswahl im Menü
    readonly property var candidates: {
        const cs = Wall.colors || [];
        const out = [];
        for (let i = 0; i < cs.length; i++) {
            const c = cs[i];
            const score = c.hsvSaturation * (0.35 + c.hsvValue);
            out.push({ c: c, score: score });
        }
        out.sort((a, b) => b.score - a.score);
        // doppelte (fast gleiche) Farben rauswerfen
        const uniq = [];
        for (const o of out) {
            if (!uniq.some(u => _hueDist(u.c.hslHue, o.c.hslHue) < 0.03 && Math.abs(u.c.hslLightness - o.c.hslLightness) < 0.12))
                uniq.push(o);
        }
        return uniq.slice(0, 8).map(o => root._liftAccent(o.c));
    }

    function _liftAccent(c) {
        const h = _hsl(c);
        return Qt.hsla(h.h, _clamp(Math.max(h.s, 0.5), 0, 0.9), _clamp(h.l, 0.62, 0.74), 1);
    }

    readonly property var _derived: {
        const cs = Wall.colors || [];
        if (cs.length === 0)
            return presets.schoko;
        const pick = Settings.data.accentPick;
        const acc = candidates[pick >= 0 && pick < candidates.length ? pick : 0] || presets.schoko.accent;
        const ah = acc.hslHue < 0 ? 0 : acc.hslHue;

        // zweiter Akzent: am weitesten weg im Farbkreis, aber noch farbig
        let acc2 = null, best = 0;
        for (const c of candidates) {
            const d = _hueDist(c.hslHue, ah);
            if (d > best && d > 0.12) { best = d; acc2 = c; }
        }
        if (!acc2)
            acc2 = Qt.hsla((ah + 0.42) % 1, 0.62, 0.7, 1);

        // dunkelste Farbe bestimmt den Grundton
        let dark = cs[0];
        for (const c of cs) if (c.hslLightness < dark.hslLightness) dark = c;
        const dh = _hsl(dark);
        const baseHue = dh.s > 0.08 ? dh.h : ah;
        const baseSat = _clamp(dh.s, 0.18, 0.4);

        return {
            base: Qt.hsla(baseHue, baseSat, 0.085, 1),
            accent: acc,
            accent2: acc2,
            text: Qt.hsla(baseHue, 0.3, 0.94, 1)
        };
    }

    readonly property var _p: Settings.data.themeMode === "wallpaper" ? _derived : (presets[Settings.data.themeMode] || presets.schoko)

    function _shift(c, dl, ds) {
        const h = _hsl(c);
        return Qt.hsla(h.h, _clamp(h.s + (ds || 0), 0, 1), _clamp(h.l + dl, 0, 1), 1);
    }

    // ------------------------------------------------------- Rollen
    property color base: _p.base
    // abgeleitete Töne hängen an den (animierten) Grundfarben, gleiten also mit
    readonly property color surface: _shift(base, 0.05, 0)
    readonly property color surface2: _shift(base, 0.10, -0.03)
    readonly property color surface3: _shift(base, 0.17, -0.06)
    property color accent: _p.accent
    property color accent2: _p.accent2
    property color text: _p.text
    readonly property color textDim: Qt.rgba(text.r, text.g, text.b, 0.62)
    readonly property color textFaint: Qt.rgba(text.r, text.g, text.b, 0.32)
    readonly property color onAccent: base
    readonly property color line: Qt.rgba(text.r, text.g, text.b, 0.09)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.45)
    readonly property color good: "#7ee0a3"
    readonly property color warn: "#ffc56b"
    readonly property color bad: "#ff7a85"
    readonly property color capsule: "#ffd84d"   // die gelbe Kapsel im Ei

    Behavior on base { ColorAnimation { duration: 900 } }
    Behavior on accent { ColorAnimation { duration: 900 } }
    Behavior on accent2 { ColorAnimation { duration: 900 } }
    Behavior on text { ColorAnimation { duration: 900 } }

    // ------------------------------------------------------- Export
    // Aufgelöste Palette nach ~/.local/state/eierschale/palette.json, damit
    // das quickdots-Menü (adapters/live/EierschaleLive.qml) mitfärben kann.
    readonly property string _exportJson: JSON.stringify({
        surface: String(_p.base), foreground: String(_p.text), accent: String(_p.accent),
        accent2: String(_p.accent2), barOpacity: Settings.data.opacity
    })
    on_ExportJsonChanged: _exportT.restart()
    property Timer _exportT: Timer {
        interval: 800
        onTriggered: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && printf %s "$2" > "$1/palette.json"',
            "sh", Quickshell.env("HOME") + "/.local/state/eierschale", root._exportJson])
    }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }

    // ------------------------------------------------------- Maße
    readonly property string font: "Adwaita Sans"
    readonly property string mono: "JetBrainsMono Nerd Font Propo"
    readonly property string icons: "JetBrainsMono Nerd Font Propo"
    readonly property int barHeight: 42
    readonly property int gap: Settings.data.floating ? 8 : 0
    readonly property int radius: Settings.data.radius
    readonly property int pad: 14

    // ------------------------------------------------------- Bewegung
    readonly property real speed: Settings.data.animSpeed
    readonly property bool motion: speed > 0
    function ms(v) { return Math.round(v * speed); }
    readonly property int tFast: ms(140)
    readonly property int tMed: ms(260)
    readonly property int tSlow: ms(480)
}
