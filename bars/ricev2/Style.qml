pragma Singleton
import QtQuick

// Static scale from both prompts (bar section 3, menus section 0). Same
// same-dir/pure-".." import rule as Colors.qml applies here.
QtObject {
    id: root

    // -- Fonts --------------------------------------------------------
    // Spec wants "Roboto Condensed" (text), "Symbols Nerd Font" (bar
    // icons) and "Material Design Icons" (menu/media icons) as three
    // separate font families. Checked on this system (fc-match by
    // codepoint, see README "Fonts"): every U+F0xxx glyph either prompt
    // uses is an nf-md-* codepoint, i.e. the same Private-Use-Area slot
    // Nerd Fonts patches Material Design Icons into -- and
    // "JetBrainsMono Nerd Font" (already installed, ships with every
    // other bar here) covers all of them. So iconFont and menuIconFont
    // both point at it instead of two fonts that aren't on the system.
    // "Roboto Condensed" itself is NOT installed -- left as-is (not
    // substituted) so Qt's silent font-fallback covers it today and it
    // upgrades automatically the moment the user installs it. See
    // README "Fehlende Pakete" for the install line.
    readonly property string textFont: "Roboto Condensed"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property string menuIconFont: "JetBrainsMono Nerd Font"
    readonly property string monoFont: "Roboto Mono"

    // -- Type scale -----------------------------------------------------
    readonly property int fontTiny: 9
    readonly property int fontCaption: 11
    readonly property int fontBody: 12
    readonly property int fontBodyLarge: 13
    readonly property int fontSubtitle: 14
    readonly property int fontTitle: 16
    readonly property int fontTitleLarge: 18
    readonly property int fontHeadline: 24

    // -- Radii ------------------------------------------------------------
    readonly property int radius2: 2
    readonly property int radius4: 4
    readonly property int radius8: 8
    readonly property int radius12: 12
    readonly property int radius16: 16
    readonly property int radius20: 20
    readonly property int radius40: 40

    // -- Spacing ----------------------------------------------------------
    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20

    // -- Animation durations (bar prompt) -----------------------------
    readonly property int anim150: 150
    readonly property int anim200: 200
    readonly property int anim300: 300
    readonly property int anim400: 400

    // -- Animation durations (menus prompt, own scale) -----------------
    readonly property int animVeryFast: 100
    readonly property int animFast: 150
    readonly property int animNormal: 200
    readonly property int animEnter: 250
    readonly property int animMedium: 300
    readonly property int animExpand: 350
    readonly property int animSlow: 400

    // -- Opacity levels -----------------------------------------------
    readonly property real opacityDim: 0.35
    readonly property real opacityMuted: 0.5
    readonly property real opacitySubtle: 0.6

    // -- Bar geometry ----------------------------------------------------
    readonly property int barHeight: 32
    readonly property int diagSlant: 28
    readonly property real islandAlpha: 0.88
    readonly property real notificationAlpha: 0.92

    // -- Middle island (bar prompt section 2/6) -------------------------
    readonly property int middleIslandWidth: 699
    // Height of each of the two cava canvases (bar prompt section 6:
    // "Zwei Canvas, je 14px hoch").
    readonly property int vizHeight: 14

    // BezierSpline easing for dropdown height (both prompts): fast out,
    // soft settle. Qt has no named curve for this -- Easing.BezierSpline
    // takes the control points directly.
    readonly property var dropdownBezier: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property int dropdownHeightMs: 320
    readonly property int dropdownLineMs: 300
    readonly property int dropdownContentMs: 200

    readonly property int dropdownMinWidth: 320

    // -- Notification popups (menus prompt section 5) -------------------
    readonly property int popupWidth: 320
    readonly property int popupEdgeMargin: 16
    readonly property int popupTopMargin: 12
    readonly property int popupSpacing: 8
    readonly property int popupMaxVisible: 4
    readonly property int popupDefaultTimeoutMs: 5000
    // Signature-detail perimeter stroke draw-on.
    readonly property int popupStrokeMs: 600
    readonly property int popupEnterMs: 350
    readonly property int popupExitMs: 250
    readonly property int popupCollapseMs: 180

    // -- Launcher / Switcher slice geometry (menus section 2/3) --------
    readonly property int sliceWidth: 135
    readonly property int sliceExpandedWidth: 924
    readonly property int sliceHeight: 520
    readonly property int sliceSkew: 35
    readonly property int sliceSpacing: -22
    readonly property int sliceVisibleCount: 12

    // -- Switcher-only overrides (menus section 3) ---------------------
    readonly property int switcherCardWidth: 1600
    readonly property int switcherCardHeightPad: 40

    // -- Launcher alternative modes (menus section 2, "Alternative Modi")
    // -- deferred at Stage 7, built afterwards (see README "Noch nicht
    // gebaut"). Spec numbers are used where given; gaps get a documented
    // judgment call rather than a guess.
    readonly property int hexRadius: 140
    readonly property int hexCols: 7
    readonly property int hexRows: 3
    readonly property int hexSpacing: 6
    readonly property real hexArcIntensity: 1.2
    // Spec gives "Intensität 1.2" for the column arc but never states what
    // it multiplies -- 40px is chosen as a base that reads as a gentle
    // honeycomb bow without pushing the card past a comfortable height on
    // this system's 1440px-tall monitor (judgment call; see
    // hexArcOffset() below and Launcher.qml's hex layout).
    readonly property int hexArcBaseUnit: 40
    readonly property real hexArcAmplitude: hexArcIntensity * hexArcBaseUnit
    // Flat-top hexagon bounding box for radius (center-to-vertex) hexRadius.
    readonly property real hexWidth: hexRadius * 2
    readonly property real hexHeight: hexRadius * Math.sqrt(3)
    readonly property real hexStepX: hexWidth * 0.75 + hexSpacing

    // Row-major fill (index = row * hexCols + col): how far (in px) column
    // `col`'s whole hex stack is pushed down, center columns pushed the
    // least so the layout bows upward in the middle.
    function hexArcOffset(col) {
        const mid = (hexCols - 1) / 2;
        const t = mid > 0 ? (col - mid) / mid : 0;
        return hexArcAmplitude * t * t;
    }

    readonly property int gridCols: 6
    readonly property int gridRowsVisible: 3
    readonly property int gridTileWidth: 300
    readonly property int gridTileHeight: 169
    readonly property int gridTileRadius: 6
    readonly property int gridSpacing: 8
}
