pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Root singleton -- kept out of a Config/ subfolder for the same reason
// as bars/lumen/Colors.qml: a pragma-Singleton only resolves reliably via
// same-dir or a pure ".." parent-chain import in this Quickshell version
// (see memory: feedback_quickshell_singleton_cross_dir_import). Modules
// reach this file via "import "../"" (or "../../"" one level deeper).
//
// Source: ~/.cache/ricev2/colors.json, written by matugen's "ricev2"
// template (~/.config/matugen/templates/ricev2-colors.json, registered in
// ~/.config/matugen/config.toml) -- NOT the ~/.cache/skwd-wall/colors.json
// path the original prompt named, and NOT pywal like every other bar in
// this repo. Reason: the prompt spec needs full Material-You roles
// (primaryContainer, surfaceContainer, outline, shadow, inversePrimary,
// ...) that pywal's 16-color scheme has no equivalent for, and matugen
// already runs on this system (bars/rice, bars/blobs use it). See
// README.md "Farben". Until the user's normal `matugen image <wallpaper>`
// run regenerates this file, every color below sits on the fallback
// palette, which is the prompt's own spec'd fallback (section 7), typed
// in verbatim -- not invented here.
QtObject {
    id: root

    property FileView _src: FileView {
        path: Quickshell.env("HOME") + "/.cache/ricev2/colors.json"
        printErrors: false
        watchChanges: true
        property var parsed: null
        onLoaded: {
            try {
                parsed = JSON.parse(text());
            } catch (e) {
                parsed = null;
            }
            root._settle();
        }
        onLoadFailed: {
            parsed = null;
            root._settle();
        }
        onFileChanged: reload()
    }

    readonly property bool _hasMatugen: root._src.parsed !== null

    function _pick(key, fallback) {
        return root._hasMatugen && root._src.parsed[key] ? root._src.parsed[key] : fallback;
    }

    // Spec fallback palette (claude-code-prompt-skwd-bar.md, section 7) --
    // used verbatim until matugen writes a real ricev2/colors.json.
    readonly property color _fbPrimary: "#ffb4ab"
    readonly property color _fbPrimaryText: "#690005"
    readonly property color _fbPrimaryContainer: "#b12723"
    readonly property color _fbSecondary: "#ffb4ab"
    readonly property color _fbSecondaryContainer: "#792f29"
    readonly property color _fbTertiary: "#8bceff"
    readonly property color _fbTertiaryContainer: "#006390"
    readonly property color _fbSurface: "#1d100e"
    readonly property color _fbSurfaceText: "#f7ddd9"
    readonly property color _fbSurfaceVariant: "#5a413e"
    readonly property color _fbSurfaceContainer: "#2c1f1d"
    readonly property color _fbError: "#ffb4ab"
    readonly property color _fbOutline: "#a98986"
    readonly property color _fbShadow: "#000000"
    readonly property color _fbInversePrimary: "#b32824"

    property bool _settled: false

    property color primary: root._fbPrimary
    property color primaryText: root._fbPrimaryText
    property color primaryContainer: root._fbPrimaryContainer
    property color secondary: root._fbSecondary
    property color secondaryContainer: root._fbSecondaryContainer
    property color tertiary: root._fbTertiary
    property color tertiaryContainer: root._fbTertiaryContainer
    // "background" and "surface" are spec'd as one shared role.
    property color background: root._fbSurface
    property color surface: root._fbSurface
    property color surfaceText: root._fbSurfaceText
    property color surfaceVariant: root._fbSurfaceVariant
    property color surfaceContainer: root._fbSurfaceContainer
    property color backgroundText: root._fbSurfaceText
    property color error: root._fbError
    property color outline: root._fbOutline
    property color shadow: root._fbShadow
    property color inversePrimary: root._fbInversePrimary

    function _settle() {
        primary = root._pick("primary", root._fbPrimary);
        primaryText = root._pick("primaryText", root._fbPrimaryText);
        primaryContainer = root._pick("primaryContainer", root._fbPrimaryContainer);
        secondary = root._pick("secondary", root._fbSecondary);
        secondaryContainer = root._pick("secondaryContainer", root._fbSecondaryContainer);
        tertiary = root._pick("tertiary", root._fbTertiary);
        tertiaryContainer = root._pick("tertiaryContainer", root._fbTertiaryContainer);
        background = root._pick("background", root._fbSurface);
        surface = root._pick("surface", root._fbSurface);
        surfaceText = root._pick("surfaceText", root._fbSurfaceText);
        surfaceVariant = root._pick("surfaceVariant", root._fbSurfaceVariant);
        surfaceContainer = root._pick("surfaceContainer", root._fbSurfaceContainer);
        backgroundText = root._pick("backgroundText", root._fbSurfaceText);
        error = root._pick("error", root._fbError);
        outline = root._pick("outline", root._fbOutline);
        shadow = root._pick("shadow", root._fbShadow);
        inversePrimary = root._pick("inversePrimary", root._fbInversePrimary);
        // Behaviors below only start animating colors on RE-settles (wallpaper
        // change, matugen re-run) -- the very first settle must land instantly,
        // otherwise the bar fades in from whatever QML's zero-color default is.
        root._settled = true;
    }

    Behavior on primary { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on primaryText { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on primaryContainer { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on secondary { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on secondaryContainer { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on tertiary { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on tertiaryContainer { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on background { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on surface { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on surfaceText { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on surfaceVariant { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainer { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on backgroundText { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on error { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on outline { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on shadow { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on inversePrimary { enabled: root._settled; ColorAnimation { duration: 180; easing.type: Easing.InOutQuad } }
}
