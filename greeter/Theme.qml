pragma Singleton
import QtQuick

// Design tokens for the greeter -- same layout as menu/Theme.qml; the colors
// follow the wallpaper (WallColors.qml): everything is tinted with its
// dominant hue, the accent is that hue made vivid.
//
// No Behavior in here: a Behavior inside a Singleton crashes Quickshell 0.3.1.
QtObject {
    // -- Colors ---------------------------------------------------------
    readonly property real hue: WallColors.hue
    // bright wallpapers get darkened more, so white text stays readable
    readonly property real dim: Math.max(0, WallColors.lum - 0.3) * 0.45

    readonly property color bg: Qt.hsla(hue, 0.16, 0.09, 1)
    readonly property color bgDeep: Qt.hsla(hue, 0.18, 0.06, 1)
    readonly property color panel: Qt.hsla(hue, 0.16, 0.12, 0.72 + dim * 0.3)
    readonly property color panelSolid: Qt.hsla(hue, 0.14, 0.14, 1)
    readonly property color panelAlt: Qt.rgba(1, 1, 1, 0.06)
    readonly property color border: Qt.hsla(hue, 0.4, 0.85, 0.12)
    readonly property color text: Qt.hsla(hue, 0.12, 0.92, 1)
    readonly property color textDim: Qt.hsla(hue, 0.08, 0.66, 1)
    readonly property color textFaint: Qt.hsla(hue, 0.06, 0.42, 1)
    readonly property color accent: Qt.hsla(hue, WallColors.sat, 0.64, 1)
    readonly property color accentText: Qt.hsla(hue, 0.35, 0.10, 1)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.08)
    readonly property color danger: "#e0525a"
    readonly property color shade: Qt.hsla(hue, 0.25, 0.04, 0.45 + dim)

    // -- Geometry -------------------------------------------------------
    readonly property int radius: 18
    readonly property int radiusSmall: 10
    readonly property int cardWidth: 380
    readonly property int avatarSize: 92
    readonly property int fieldHeight: 46
    readonly property int chipHeight: 38

    readonly property int spacingXs: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 18
    readonly property int spacingXl: 28
    readonly property int edge: 36

    // -- Fonts ----------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property string fontMono: "JetBrainsMono Nerd Font Mono"
    readonly property string fontSans: "Adwaita Sans"
    readonly property int fontS: 11
    readonly property int fontM: 13
    readonly property int fontL: 17
    readonly property int fontXl: 22
    readonly property int fontClock: 108

    // -- Motion ---------------------------------------------------------
    readonly property int animFast: 140
    readonly property int animMid: 260
    readonly property int animSlow: 520
}
