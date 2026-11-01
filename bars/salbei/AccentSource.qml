pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Accent color: fixed, or taken from the current wallpaper. Settings come from
// salbei-widgets.json (quickdots menu, "Widgets" tab: accentMode / accentColor /
// accentPick). The wallpaper is shrunk to a small color grid (magick); the
// strongest clearly different hues become pastel candidates (same calm look
// as the sage default) and accentPick chooses one. Candidates + grid are
// written to salbei-palette.json so the menu can show swatches and a preview.
// The grid also tells each desktop widget how bright the wallpaper is under
// it (lumAt) -- "An Hintergrund anpassen" in the menu.
//
// Not named "Palette": that name is taken by QtQuick's own Palette type.
// Lives next to Theme.qml (not in services/) so Theme can read it without a
// circular directory import. No Behavior here: Behaviors inside singletons
// crash Quickshell 0.3.1.
Singleton {
    id: root

    readonly property color fallback: "#A8D5A2"

    property string mode: "fixed"          // "fixed" | "wallpaper"
    property color fixedColor: fallback
    property int pick: 0
    property string wallpaper: ""
    property var candidates: []            // pastel accents from the wallpaper

    readonly property color accent: mode === "wallpaper" && candidates.length > 0
        ? candidates[Math.max(0, Math.min(candidates.length - 1, pick))]
        : fixedColor
    // dark ink of the same hue for text/icons on accent surfaces
    readonly property color accentInk: Qt.hsla(accent.hslHue < 0 ? 0.33 : accent.hslHue,
                                               Math.min(0.35, accent.hslSaturation), 0.12, 1)

    // ── settings ─────────────────────────────────────────────
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/salbei-widgets.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let d = {};
            try { d = JSON.parse(text()); } catch (e) {}
            root.mode = d.accentMode === "wallpaper" ? "wallpaper" : "fixed";
            root.fixedColor = /^#[0-9a-fA-F]{6}$/.test(d.accentColor ?? "") ? d.accentColor : root.fallback;
            root.pick = d.accentPick ?? 0;
        }
    }

    // ── wallpaper ────────────────────────────────────────────
    // awww has no change events; a cheap query every 15 s. Always on: the
    // desktop widgets read the wallpaper brightness under them (lumAt).
    Process {
        id: query
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "" && p !== root.wallpaper) root.wallpaper = p;
            }
        }
    }
    Timer {
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: true
        onTriggered: query.running = true
    }

    // The wallpaper shrunk to a gridW × gridH grid of average colors, via
    // magick (Qt here can't decode webp, magick can). Source of both the
    // accent candidates and the per-widget brightness (lumAt).
    readonly property int gridW: 32
    readonly property int gridH: 18
    property var grid: []                  // [r, g, b, r, g, b, …] 0..255, row-major
    // command set here, not bound: the binding may not have caught up yet
    // when this handler runs
    onWallpaperChanged: {
        if (wallpaper === "") return;
        sampler.command = ["sh", "-c", "magick \"$1\"'[0]' -resize " + gridW + "x" + gridH + "! -depth 8 rgb:- | od -An -tu1 -v",
                           "sh", wallpaper];
        sampler.running = true;
    }

    Process {
        id: sampler
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split(/\s+/).map(Number);
                if (v.length !== root.gridW * root.gridH * 3) return;
                root.grid = v;
                root.build();
            }
        }
    }

    // Average relative luminance (0 dark … 1 bright) of the wallpaper inside
    // a rect given in screen fractions. 0.2 (dark) while nothing is sampled.
    function lumAt(x0, y0, x1, y1) {
        const g = grid;
        if (g.length === 0) return 0.2;
        const cx0 = Math.max(0, Math.min(gridW - 1, Math.floor(x0 * gridW)));
        const cx1 = Math.max(cx0, Math.min(gridW - 1, Math.ceil(x1 * gridW) - 1));
        const cy0 = Math.max(0, Math.min(gridH - 1, Math.floor(y0 * gridH)));
        const cy1 = Math.max(cy0, Math.min(gridH - 1, Math.ceil(y1 * gridH) - 1));
        let sum = 0, n = 0;
        for (let y = cy0; y <= cy1; y++)
            for (let x = cx0; x <= cx1; x++) {
                const i = (y * gridW + x) * 3;
                sum += (0.2126 * g[i] + 0.7152 * g[i + 1] + 0.0722 * g[i + 2]) / 255;
                n++;
            }
        return n ? sum / n : 0.2;
    }

    // Accent candidates: hues binned (24 bins) and weighted by saturation, so
    // a large calm area beats a tiny colorful speck; neighbouring hues are
    // merged, the five strongest become pastels.
    function build() {
        const g = grid;
        const bins = [];
        for (let i = 0; i < g.length; i += 3) {
            const c = Qt.rgba(g[i] / 255, g[i + 1] / 255, g[i + 2] / 255, 1);
            if (c.hslHue < 0 || c.hslSaturation < 0.12) continue;
            if (c.hslLightness < 0.1 || c.hslLightness > 0.92) continue;
            const b = Math.min(23, Math.floor(c.hslHue * 24));
            const w = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.2);
            const bin = bins[b] ?? (bins[b] = { w: 0, r: 0, g: 0, b: 0 });
            bin.w += w;
            bin.r += c.r * w; bin.g += c.g * w; bin.b += c.b * w;
        }
        const raw = [];
        for (const bin of bins) {
            if (!bin || bin.w <= 0) continue;
            const c = Qt.rgba(bin.r / bin.w, bin.g / bin.w, bin.b / bin.w, 1);
            raw.push({ h: c.hslHue, s: c.hslSaturation, score: bin.w });
        }
        raw.sort((a, b) => b.score - a.score);
        const out = [];
        for (const r of raw) {
            if (out.some(o => Math.min(Math.abs(o.h - r.h), 1 - Math.abs(o.h - r.h)) < 0.06)) continue;
            out.push(r);
            if (out.length >= 5) break;
        }
        root.candidates = out.map(r => Qt.hsla(r.h, Math.max(0.28, Math.min(0.55, r.s)), 0.74, 1));
        writePalette();
    }

    // tell the menu what we found (+ the grid, for its live preview)
    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/salbei-palette.json"
        printErrors: false
        atomicWrites: true
    }
    function writePalette() {
        paletteFile.setText(JSON.stringify({
            wallpaper: root.wallpaper,
            candidates: root.candidates.map(c => c.toString()),
            gridW: root.gridW,
            gridH: root.gridH,
            grid: root.grid
        }));
    }
}
