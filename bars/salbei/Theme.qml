pragma Singleton

import QtQuick
import Quickshell

// All design tokens for the shell. Change colors, fonts, radii and spacing here only.
Singleton {
    id: root

    // ── colors ───────────────────────────────────────────────
    // Fixed (default sage #A8D5A2) or taken from the wallpaper: see AccentSource.qml,
    // set in the quickdots menu, "Widgets" tab → "Akzentfarbe".
    readonly property color accent: AccentSource.accent
    // Text/icons on accent-filled surfaces. Spec name was "onAccent", but QML treats
    // properties named on+Capital as signal handlers (they silently stay black).
    readonly property color accentInk: AccentSource.accentInk

    readonly property color text: "#E8EDE6"
    readonly property color textDim: "#9DA89C"
    readonly property color textFaint: "#6B766B"
    readonly property color danger: "#E59A8C"          // warm red tint: low battery, destructive confirm

    readonly property color panelTint: Qt.rgba(18 / 255, 26 / 255, 20 / 255, 0.62)
    readonly property color panelFrom: Qt.rgba(24 / 255, 36 / 255, 26 / 255, 0.70)   // top-left
    readonly property color panelTo: Qt.rgba(70 / 255, 28 / 255, 40 / 255, 0.55)     // bottom-right
    readonly property color tile: Qt.rgba(1, 1, 1, 0.05)
    readonly property color tileActive: accent
    readonly property color border: Qt.rgba(1, 1, 1, 0.08)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.08)
    readonly property color inset: Qt.rgba(0, 0, 0, 0.35)              // search field
    readonly property color insetBorder: Qt.rgba(1, 1, 1, 0.18)
    readonly property color insetBorderFocus: Qt.rgba(1, 1, 1, 0.70)
    readonly property color track: Qt.rgba(1, 1, 1, 0.12)              // slider track
    readonly property color textShadow: Qt.rgba(0, 0, 0, 0.55)

    // ── radii ────────────────────────────────────────────────
    readonly property int radiusPanel: 18
    readonly property int radiusTile: 14
    readonly property int radiusRow: 8
    readonly property int radiusButton: 10
    readonly property int radiusField: 10
    readonly property int radiusPill: 10
    readonly property int radiusIconButton: 8
    readonly property int radiusDay: 6

    // ── spacing ──────────────────────────────────────────────
    readonly property int grid: 8
    readonly property int panelPadding: 14
    readonly property int tileGap: 8
    readonly property int rowHeight: 34

    // ── bar ──────────────────────────────────────────────────
    readonly property real barWidthFraction: 0.48
    readonly property int barHeight: 36
    readonly property int barMargin: 6
    readonly property int barPadding: 14
    readonly property int barSpacing: 14

    // ── fonts ────────────────────────────────────────────────
    // First installed family wins, so installing Outfit / Material Symbols later just works.
    readonly property var _families: Qt.fontFamilies()
    function _pick(list) {
        for (let i = 0; i < list.length; i++)
            if (_families.indexOf(list[i]) >= 0) return list[i];
        return "sans-serif";
    }
    readonly property string fontFamily: _pick(["Outfit", "Lexend", "Adwaita Sans", "Inter", "DejaVu Sans"])
    readonly property bool materialIcons: _families.indexOf("Material Symbols Rounded") >= 0
    readonly property string iconFamily: materialIcons ? "Material Symbols Rounded" : "JetBrainsMono Nerd Font Propo"

    readonly property int fontBar: 13
    readonly property int fontItem: 13
    readonly property int fontSmall: 12
    readonly property int fontTiny: 11
    readonly property int fontHeading: 14
    readonly property int fontName: 15
    readonly property int fontClockCard: 22

    readonly property int iconBar: 16
    readonly property int iconItem: 18

    // ── motion ───────────────────────────────────────────────
    readonly property int animFast: 150
    readonly property int animNormal: 200
    readonly property int animSlow: 380
    readonly property int animOpen: 340          // popup open (spring); close uses animNormal
    readonly property int animStagger: 28        // delay between list items / tiles fading in
    readonly property int staggerMax: 12         // items after this appear together
    readonly property int easing: Easing.OutCubic
    readonly property int easingSpring: Easing.OutBack
    readonly property int easingEmph: Easing.OutExpo
    readonly property real panelScaleFrom: 0.92
    readonly property real panelSlide: 14        // px a popup glides in from
    readonly property real pressScale: 0.94      // buttons/tiles while pressed

    // ── sizes of the big surfaces ────────────────────────────
    readonly property int launcherWidth: 520
    readonly property int launcherHeight: 470
    readonly property int ccWidth: 760
    readonly property int ccHeight: 490
    readonly property int ccSidebar: 180
    readonly property int toastWidth: 340
    readonly property int toastTimeout: 5000

    // ── desktop widgets ──────────────────────────────────────
    // visibility, clock size/position, calendar width and visualizer size are set
    // live in the quickdots menu ("Widgets" tab) → services/WidgetSettings.qml
    readonly property int eventsWidth: 120
    readonly property int visualizerBarWidth: 2
    readonly property int visualizerBarGap: 2

    // ── polling ──────────────────────────────────────────────
    readonly property int statsInterval: 2000

    // ── server page (SSH over Tailscale) ─────────────────────
    readonly property string serverHost: "PRIVATE_VALUE"             // Tailscale name
    readonly property string serverFallback: "TAILSCALE_FALLBACK_IP" // used if the name doesn't resolve
    readonly property string serverUser: ""                  // empty = same as local user
    readonly property int serverInterval: 3000

    // ── terminal ─────────────────────────────────────────────
    readonly property string terminal: "kitty"
}
