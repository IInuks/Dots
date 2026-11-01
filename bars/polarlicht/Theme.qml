pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Adaptives Farbschema: liest das aktuelle awww-Wallpaper, quantisiert seine
// Farben und baut daraus eine komplette Palette (hell/dunkel automatisch).
Singleton {
    id: root

    // ── Einstellungen (in ~/.local/state/quickshell/.../settings.json) ──
    readonly property var cfg: adapter
    FileView {
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: adapter
            property string mode: "auto"      // auto | dark | light
            property string scheme: "tonal"   // tonal | vibrant | mono
            property real anim: 1.0           // 1 = normal, 0.55 = flott, 0 = aus
            property int seedPick: -1         // -1 = automatisch, sonst Index in swatches
            property bool caffeine: false
            property bool clockSeconds: false
            property string wallDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
        }
    }

    function dur(ms) { return Math.round(ms * adapter.anim) }

    readonly property string font: "JetBrainsMono Nerd Font Propo"

    // ── Wallpaper verfolgen ──
    property string wallpaper: ""
    Process {
        id: query
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image: (.+)$/m)
                if (m && m[1].trim() !== root.wallpaper) root.wallpaper = m[1].trim()
            }
        }
    }
    Timer {
        interval: 6000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: query.running = true
    }

    ColorQuantizer {
        id: cq
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        depth: 3
        rescaleSize: 96
    }

    readonly property var swatches: cq.colors ?? []

    readonly property color seed: {
        const c = swatches
        if (!c || c.length === 0) return "#7aa2f7"
        if (adapter.seedPick >= 0 && adapter.seedPick < c.length) return c[adapter.seedPick]
        let best = c[0], bs = -1
        for (const x of c) {
            const s = x.hslSaturation * (1 - Math.abs(x.hslLightness - 0.5) * 1.3)
            if (s > bs) { bs = s; best = x }
        }
        return best
    }

    // zweite Farbe: möglichst weit weg vom Seed-Farbton
    readonly property real hue2: {
        const c = swatches
        let best = (hue + 0.14) % 1, bs = 0.05
        for (const x of c) {
            if (x.hslHue < 0) continue
            let d = Math.abs(x.hslHue - hue); d = Math.min(d, 1 - d)
            const s = d * x.hslSaturation
            if (s > bs) { bs = s; best = x.hslHue }
        }
        return best
    }

    readonly property real wallLum: {
        const c = swatches
        if (!c || c.length === 0) return 0.2
        let l = 0
        for (const x of c) l += 0.2126 * x.r + 0.7152 * x.g + 0.0722 * x.b
        return l / c.length
    }

    readonly property bool dark: adapter.mode === "dark" || (adapter.mode === "auto" && wallLum < 0.58)
    readonly property real hue: seed.hslHue < 0 ? 0.62 : seed.hslHue
    readonly property real ns: adapter.scheme === "vibrant" ? 0.34 : adapter.scheme === "mono" ? 0.02 : 0.16
    readonly property real accSat: adapter.scheme === "mono" ? 0.06
                             : adapter.scheme === "vibrant" ? 0.88
                             : Math.max(0.42, Math.min(0.72, seed.hslSaturation))

    function n(l, a) { return Qt.hsla(hue, ns, l, a === undefined ? 1 : a) }

    // ── Palette (Zielwerte) ──
    readonly property color _bg:        dark ? n(0.075, 0.90) : n(0.955, 0.92)
    readonly property color _surface:   dark ? n(0.13) : n(0.905)
    readonly property color _surfaceHi: dark ? n(0.19) : n(0.85)
    readonly property color _outline:   dark ? n(0.27, 0.8) : n(0.72, 0.8)
    readonly property color _text:      dark ? Qt.hsla(hue, 0.18, 0.93, 1) : Qt.hsla(hue, 0.3, 0.11, 1)
    readonly property color _textDim:   dark ? Qt.hsla(hue, 0.10, 0.66, 1) : Qt.hsla(hue, 0.12, 0.38, 1)
    readonly property color _accent:    dark ? Qt.hsla(hue, accSat, 0.72, 1) : Qt.hsla(hue, accSat, 0.42, 1)
    readonly property color _accent2:   dark ? Qt.hsla(hue2, accSat * 0.9, 0.74, 1) : Qt.hsla(hue2, accSat * 0.9, 0.40, 1)
    readonly property color _onAccent:  dark ? Qt.hsla(hue, 0.5, 0.12, 1) : Qt.hsla(hue, 0.2, 0.98, 1)

    // ── Überblendung: Behaviors crashen in Singletons, darum manuell ──
    readonly property var keys: ["bg", "surface", "surfaceHi", "outline", "text", "textDim", "accent", "accent2", "onAccent"]
    property var from: ({})
    property real t: 1
    NumberAnimation { id: blend; target: root; property: "t"; from: 0; to: 1; duration: root.dur(900); easing.type: Easing.InOutQuad }

    function mix(k) {
        const b = root["_" + k], a = from[k]
        if (a === undefined || t >= 1) return b
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }
    readonly property string sig: keys.map(k => root["_" + k].toString()).join()
    onSigChanged: {
        const f = {}
        for (const k of keys) f[k] = Qt.color(root[k])
        from = f
        t = 0
        blend.restart()
    }

    readonly property color bg: mix("bg")
    readonly property color surface: mix("surface")
    readonly property color surfaceHi: mix("surfaceHi")
    readonly property color outline: mix("outline")
    readonly property color text: mix("text")
    readonly property color textDim: mix("textDim")
    readonly property color accent: mix("accent")
    readonly property color accent2: mix("accent2")
    readonly property color onAccent: mix("onAccent")
    readonly property color bgSolid: Qt.rgba(bg.r, bg.g, bg.b, 0.97)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.18 : 0.16)
    readonly property color danger: dark ? "#f28b82" : "#c5221f"
    readonly property color shade: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.22)
}
