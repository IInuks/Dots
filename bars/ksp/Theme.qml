pragma Singleton
import QtQuick

// "Mission Control" palette -- fixed dark charcoal/steel panels (no
// light/adaptive modes here, unlike the sibling bars: this build's whole
// point is the KSP look, not theme-switching), three swappable accent
// "liveries" that stand in for KSP's faction colors.
//
// Named "Theme" rather than "Palette"/"Colors" and "Metrics" rather than
// "Layout" for the same reason every sibling bar does: those names
// silently shadow QtQuick/Quickshell builtins wherever `import
// QtQuick`/`import Quickshell` is present, and every property then reads
// back undefined with no error anywhere (see bars/chamaeleon/Theme.qml).
QtObject {
    id: root

    readonly property var _liveries: ({
        orange: "#ff8c1a",
        cyan: "#2fd9d0",
        crimson: "#ff4d4d",
        phosphor: "#39ff14"
    })

    property color accent: root._liveries[Config.livery] || root._liveries.orange
    Behavior on accent { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }

    function colorFor(liveryKey) { return root._liveries[liveryKey] || root._liveries.orange; }

    readonly property color ink: "#0a0c10"
    readonly property color panel: "#151a20"
    readonly property color panelRaised: "#1e242c"
    readonly property color panelBright: "#2a323c"
    readonly property color text: "#eef1f5"
    readonly property color textFaint: "#7c8794"

    readonly property color good: "#4be36a"
    readonly property color warn: "#ffcc2e"
    readonly property color bad: "#ff4545"

    readonly property real barAlpha: Config.barAlpha
    readonly property int rSmall: 4
    readonly property int rMed: 6
    readonly property int rBar: 3

    readonly property int tFast: 120
    readonly property int tMed: 230
    readonly property int tSlow: 420

    readonly property var liveryOrder: ["orange", "cyan", "crimson", "phosphor"]
    readonly property var liveryLabels: ({ orange: "KERBIN", cyan: "MUN", crimson: "DUNA", phosphor: "PHOSPHOR" })

    // CRT overlay tuning -- derived from Config so every panel/bar just
    // binds to Theme instead of reading Config directly.
    readonly property real crtScanlineOpacity: Config.crtEffects ? 0.025 + Config.crtIntensity * 0.075 : 0
    readonly property real crtVignette: Config.crtEffects ? 0.12 + Config.crtIntensity * 0.38 : 0
    readonly property bool crtFlicker: Config.crtEffects && Config.crtFlicker
}
