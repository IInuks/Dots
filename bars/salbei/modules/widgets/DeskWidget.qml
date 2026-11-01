import QtQuick
import QtQuick.Effects
import "../../"
import "../../services"

// One movable desktop widget (child of Desktop's stage). Everything generic
// comes from WidgetSettings by `key`: <key>Visible, <key>X / <key>Y (top-left
// in % of the screen, clamped so it stays on screen), <key>Adapt and
// <key>Backdrop. The size is the size of the single content child.
//
// Adapt: the wallpaper brightness under the widget (AccentSource.lumAt)
// switches between light ink (dark wallpaper) and dark ink + a deeper accent
// (bright wallpaper). Content binds to ink / inkDim / inkFaint / accent /
// accentInk / hoverTint instead of the Theme colors.
Item {
    id: w

    required property string key
    property real intro: 1               // 0 → 1 startup animation, set by Desktop
    property real introDx: 0             // where it glides in from
    property real introDy: 30
    property bool available: true        // extra condition (media: a player exists)
    property bool backdropAllowed: true
    property real pad: 18                // glass card margin around the content
    default property alias content: body.data

    readonly property bool shown: WidgetSettings.v(key + "Visible") === true && available
    readonly property bool adapt: WidgetSettings.v(key + "Adapt") !== false
    readonly property bool backdrop: backdropAllowed && WidgetSettings.v(key + "Backdrop") === true

    readonly property Item _child: body.children.length > 0 ? body.children[0] : null
    width: _child ? _child.width : 0
    height: _child ? _child.height : 0

    readonly property real areaW: parent ? parent.width : 1
    readonly property real areaH: parent ? parent.height : 1
    readonly property real margin: backdrop ? pad : 0
    x: Math.round(Math.max(margin, Math.min(areaW - width - margin, areaW * (WidgetSettings.v(key + "X") ?? 0) / 100)))
    y: Math.round(Math.max(margin, Math.min(areaH - height - margin, areaH * (WidgetSettings.v(key + "Y") ?? 0) / 100)))

    // ── colors ───────────────────────────────────────────────
    readonly property real bgLum: adapt
        ? AccentSource.lumAt((x - margin) / areaW, (y - margin) / areaH,
                             (x + width + margin) / areaW, (y + height + margin) / areaH)
        : 0
    // with a card, the card decides: frosted white on bright, smoked on dark
    readonly property bool onLight: bgLum > 0.58

    readonly property color _deep: Qt.hsla(Theme.accent.hslHue < 0 ? 0.33 : Theme.accent.hslHue,
                                           Math.min(0.65, Theme.accent.hslSaturation + 0.15), 0.32, 1)
    property color ink: onLight ? "#17201A" : Theme.text
    property color inkDim: onLight ? Qt.rgba(0.09, 0.13, 0.1, 0.74) : Theme.textDim
    property color inkFaint: onLight ? Qt.rgba(0.09, 0.13, 0.1, 0.5) : Theme.textFaint
    property color accent: onLight ? _deep : Theme.accent
    property color accentInk: onLight ? "#F3F6F1" : Theme.accentInk
    property color hoverTint: onLight ? Qt.rgba(0, 0, 0, 0.08) : Theme.hover
    property color track: onLight ? Qt.rgba(0, 0, 0, 0.14) : Theme.track
    readonly property color shadow: onLight ? Qt.rgba(1, 1, 1, 0.35) : Theme.textShadow

    Behavior on ink { ColorAnimation { duration: Theme.animSlow } }
    Behavior on inkDim { ColorAnimation { duration: Theme.animSlow } }
    Behavior on inkFaint { ColorAnimation { duration: Theme.animSlow } }
    Behavior on accent { ColorAnimation { duration: Theme.animSlow } }
    Behavior on accentInk { ColorAnimation { duration: Theme.animSlow } }
    Behavior on track { ColorAnimation { duration: Theme.animSlow } }

    // ── show / hide ──────────────────────────────────────────
    property real showT: shown ? 1 : 0
    Behavior on showT { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easing } }
    opacity: showT * intro
    scale: 0.94 + 0.06 * showT
    visible: opacity > 0.01
    transform: Translate { x: (1 - w.intro) * w.introDx; y: (1 - w.intro) * w.introDy }

    Behavior on x { enabled: w.visible; NumberAnimation { duration: 90; easing.type: Theme.easing } }
    Behavior on y { enabled: w.visible; NumberAnimation { duration: 90; easing.type: Theme.easing } }

    // glass card
    Rectangle {
        anchors.fill: parent
        anchors.margins: -w.pad
        radius: Theme.radiusPanel
        visible: opacity > 0
        opacity: w.backdrop ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
        color: w.onLight ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(14 / 255, 20 / 255, 16 / 255, 0.42)
        border.width: 1
        border.color: w.onLight ? Qt.rgba(1, 1, 1, 0.55) : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.animSlow } }
    }

    Item {
        id: body
        anchors.fill: parent
        layer.enabled: !w.backdrop
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: w.shadow
            shadowBlur: 0.7
            shadowVerticalOffset: w.onLight ? 0 : 1
        }
    }
}
