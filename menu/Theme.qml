pragma Singleton
import QtQuick

// Fixed design tokens for the wizard-style menu (Calamares look). Every
// color, font size, spacing and duration of shell.qml, components/ and
// steps/ comes from here -- change it in one place.
//
// Pure constants only: no Behavior/animation in here, a Behavior inside a
// Singleton crashes Quickshell 0.3.1 on startup.
//
// The app search popup (AppSearch.qml) keeps using ThemeAdapter (live
// colors of the active bar); this palette is only for the wizard.
QtObject {
    // -- Colors ---------------------------------------------------------
    readonly property color bg: "#1a1d21"          // window background
    readonly property color panel: "#212529"       // list / preview panels
    readonly property color panelAlt: "#2a2f35"    // inputs, chips, hover
    readonly property color titleBar: "#16181c"
    readonly property color border: "#30353c"
    readonly property color text: "#e6e8eb"
    readonly property color textDim: "#9aa1a9"
    readonly property color textFaint: "#5f666e"
    readonly property color accent: "#00c8c8"      // active step, borders
    readonly property color accentText: "#0d1a1a"  // text on accent pill
    readonly property color select: "#3daee9"      // list selection
    readonly property color selectText: "#ffffff"
    readonly property color hover: Qt.rgba(1, 1, 1, 0.05)
    readonly property color success: "#3ecf8e"
    readonly property color danger: "#e0525a"
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)

    // Compatibility names used by the custom-bar editor (custom/*.qml).
    readonly property color foreground: text
    readonly property color surface: bg

    // -- Geometry -------------------------------------------------------
    readonly property int radius: 12        // window
    readonly property int radiusMid: 10     // panels
    readonly property int radiusSmall: 8    // buttons, list rows, chips
    readonly property int borderWidth: 1

    readonly property int windowWidth: 1100
    readonly property int windowHeight: 620
    readonly property int maximizedMargin: 40

    readonly property int titleBarHeight: 40
    readonly property int stepBarHeight: 52
    readonly property int buttonHeight: 34
    readonly property int listRowHeight: 44

    readonly property int spacingXs: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 18
    readonly property int spacingXl: 28

    // -- Fonts ----------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property string monoFamily: "JetBrainsMono Nerd Font Mono"
    readonly property int fontXs: 10
    readonly property int fontS: 11
    readonly property int fontM: 13
    readonly property int fontL: 16
    readonly property int fontXl: 22
    readonly property int fontHuge: 30

    // -- Motion ---------------------------------------------------------
    readonly property int animFast: 120
    readonly property int animPage: 200
    readonly property int animWindow: 220
}
