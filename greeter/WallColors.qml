pragma Singleton
import QtQuick
import Quickshell

// The wallpaper and the colors taken from it. Theme.qml derives its palette
// from `hue`/`lum`, so the whole greeter follows the user's wallpaper.
//
// Wallpaper order: $QD_GREETER_WALLPAPER (launch.sh points it at the copy
// scripts/wallsync.sh keeps in sync with awww), else the bundled one.
// No Behavior here: Behaviors inside singletons crash Quickshell 0.3.1.
Singleton {
    id: root

    readonly property string wallpaper: {
        const env = Quickshell.env("QD_GREETER_WALLPAPER");
        return env ? "file://" + env : Qt.resolvedUrl("wallpaper.jpg");
    }

    // teal of the original palette, used for gray wallpapers
    readonly property color fallback: "#00c8c8"

    ColorQuantizer {
        id: cq
        source: root.wallpaper
        depth: 4
        rescaleSize: 96
    }
    readonly property var swatches: cq.colors ?? []

    // true once the colors are known -- or given up on (image failed), so
    // the greeter never waits forever
    property bool ready: false
    onSwatchesChanged: if (swatches.length > 0) ready = true
    Timer {
        interval: 1500
        running: !root.ready
        onTriggered: root.ready = true
    }

    // Accent seed: the most colorful swatch, favouring mid lightness over
    // near-black/near-white specks. Null for (almost) gray wallpapers.
    readonly property var seed: {
        let best = null, bs = 0.08;
        for (const c of swatches) {
            if (c.hslHue < 0) continue;
            const s = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.4);
            if (s > bs) { bs = s; best = c; }
        }
        return best;
    }
    readonly property bool tinted: seed !== null
    readonly property real hue: tinted ? seed.hslHue : fallback.hslHue
    readonly property real sat: tinted ? Math.max(0.45, Math.min(0.8, seed.hslSaturation)) : fallback.hslSaturation

    // mean relative luminance, 0 dark … 1 bright (median cut swatches are
    // roughly equal-sized buckets, so a plain average is close enough)
    readonly property real lum: {
        if (swatches.length === 0) return 0.25;
        let sum = 0;
        for (const c of swatches) sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return sum / swatches.length;
    }
}
