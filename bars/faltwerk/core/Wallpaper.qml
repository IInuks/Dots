pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adaptives Papier: liest das aktuelle awww-Wallpaper, quantisiert es mit
// magick auf 12 Farben (magick statt ColorQuantizer, weil Qt hier kein webp
// laden kann) und leitet daraus eine komplette Faltwerk-Palette ab:
// dunkles Wallpaper -> dunkles Papier, helles -> helles, jeweils in den
// Grundton getoent; Akzent = kraeftigste Farbe, Zweitfarbe = kraeftigste
// mit deutlich anderem Farbton.
//
// `palette` ist die angewendete Palette. Aendert sich das Wallpaper, waehrend
// "adaptiv" aktiv ist, liegt die neue erst in `next`, und die Leiste
// blaettert um (Paper.refresh -> Bar flip -> Paper.commit -> apply()).
//
// KEIN `Behavior` hier (Singleton).
Singleton {
    id: root

    property string path: ""
    property var palette: fallback()
    property var next: null

    function fallback() {
        return {
            title: "Adaptiv", note: "wartet aufs Wallpaper", accentInk: "#ffffff",
            paper: "#ece6dc", deep: "#dcd3c4", ink: "#2a2622", soft: "#776d62",
            accent: "#5b7fa8", second: "#c4703a", grain: 0.10, dark: false,
            tiles: ["#5b7fa8", "#c4703a", "#5a8a6a", "#9a5a8a", "#b89a3a", "#4a7a8a", "#a85a4a", "#6a6aa8"]
        };
    }

    function apply() {
        if (next) {
            palette = next;
            next = null;
        }
    }

    // ---- Wallpaper beobachten (alle 5 s ein kurzes `awww query`) ----
    property Timer _poll: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
    property Process _query: Process {
        id: query
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /image:\s*(.+)$/m.exec(text);
                const p = m ? m[1].trim() : "";
                if (p !== "" && p !== root.path) {
                    root.path = p;
                    quant.command = ["magick", p, "-resize", "96x96^", "-colors", "12", "-depth", "8", "-format", "%c", "histogram:info:-"];
                    quant.running = true;
                }
            }
        }
    }
    property Process _quant: Process {
        id: quant
        stdout: StdioCollector {
            onStreamFinished: root._derive(text)
        }
    }

    // ---- Palette ableiten ----
    function _hueDist(a, b) {
        const d = Math.abs(a - b) % 1;
        return Math.min(d, 1 - d);
    }
    function _lum(c) {
        const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    }

    function _derive(text) {
        const cols = [];
        let total = 0;
        for (const line of text.split("\n")) {
            const m = /^\s*(\d+):.*?(#[0-9A-Fa-f]{6})/.exec(line);
            if (!m)
                continue;
            const n = Number(m[1]);
            const hx = m[2];
            const c = Qt.rgba(parseInt(hx.slice(1, 3), 16) / 255, parseInt(hx.slice(3, 5), 16) / 255, parseInt(hx.slice(5, 7), 16) / 255, 1);
            cols.push({ n: n, c: c, h: Math.max(0, c.hslHue), s: c.hslSaturation, l: c.hslLightness });
            total += n;
        }
        if (cols.length === 0)
            return;
        cols.sort((a, b) => b.n - a.n);

        // Helligkeit und Grundton (gewichtet nach Flaeche)
        let lumSum = 0;
        for (const x of cols)
            lumSum += _lum(x.c) * x.n;
        const dark = lumSum / total < 0.22;
        const colorful = cols.filter(x => x.s > 0.12 && x.l > 0.08 && x.l < 0.94);
        const base = colorful.length ? colorful.reduce((a, b) => (b.n * b.s > a.n * a.s ? b : a)) : cols[0];
        const h = base.h;
        const bs = Math.min(base.s, dark ? 0.28 : 0.32);

        // Akzent: kraeftig + nicht zu selten
        const score = x => x.s * Math.pow(x.n / total, 0.3) * (x.l > 0.12 && x.l < 0.9 ? 1 : 0.2);
        const byScore = cols.slice().sort((a, b) => score(b) - score(a));
        const acc = byScore[0];
        let sec = byScore.find(x => _hueDist(x.h, acc.h) > 0.11 && x.s > 0.15);
        const accH = acc.s > 0.1 ? acc.h : (h + 0.05) % 1;
        const secH = sec ? sec.h : (accH + 0.42) % 1;
        const accS = Math.max(0.55, Math.min(0.85, acc.s));
        const secS = Math.max(0.45, Math.min(0.8, sec ? sec.s : 0.5));

        const accent = Qt.hsla(accH, accS, dark ? 0.62 : 0.46, 1);
        const second = Qt.hsla(secH, secS, dark ? 0.68 : 0.40, 1);

        // Kaertchenfarben: alle bunten Wallpaperfarben, auf gleiche
        // Helligkeit gebracht, notfalls per Farbkreis aufgefuellt
        const tiles = [];
        const used = [];
        for (const x of colorful.concat(byScore)) {
            if (tiles.length >= 8)
                break;
            if (used.some(u => _hueDist(u, x.h) < 0.05))
                continue;
            used.push(x.h);
            tiles.push(Qt.hsla(x.h, Math.max(0.45, Math.min(0.75, x.s)), dark ? 0.6 : 0.47, 1));
        }
        for (let i = 1; tiles.length < 8; i++)
            tiles.push(Qt.hsla((accH + i * 0.137) % 1, 0.55, dark ? 0.6 : 0.47, 1));

        const file = path.split("/").pop();
        const pal = {
            title: "Adaptiv",
            note: "aus " + (file.length > 26 ? file.slice(0, 24) + "…" : file),
            paper: dark ? Qt.hsla(h, bs, 0.14, 1) : Qt.hsla(h, bs, 0.92, 1),
            deep: dark ? Qt.hsla(h, bs, 0.09, 1) : Qt.hsla(h, bs, 0.83, 1),
            ink: dark ? Qt.hsla(h, 0.18, 0.90, 1) : Qt.hsla(h, 0.30, 0.15, 1),
            soft: dark ? Qt.hsla(h, 0.14, 0.62, 1) : Qt.hsla(h, 0.16, 0.44, 1),
            accent: accent,
            second: second,
            accentInk: _lum(accent) > 0.4 ? (dark ? Qt.hsla(h, bs, 0.12, 1) : Qt.hsla(h, 0.3, 0.12, 1)) : "#ffffff",
            grain: dark ? 0.18 : 0.10,
            dark: dark,
            tiles: tiles
        };

        if (Store.paperName === "adaptiv" && Store.loaded && palette.note !== "wartet aufs Wallpaper") {
            next = pal;
            Paper.refresh();
        } else {
            palette = pal;
        }
    }
}
