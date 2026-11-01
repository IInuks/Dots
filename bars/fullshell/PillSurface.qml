import QtQuick

// Reusable glassy rounded surface shared by the bar capsule, the Command
// Center panel and its buttons: a soft border plus a slow breathing glow
// ring so "everything animates" even when nothing is being interacted
// with. `glow` toggles the breathing animation (bar + Command Center only
// -- small buttons stay static so the effect doesn't get noisy).
Rectangle {
    id: root
    radius: Theme.radiusPill
    color: Qt.alpha(Theme.surface, Theme.barAlpha)
    border.width: 1
    border.color: root._borderColor

    property bool glow: false
    readonly property color _glowColor: Theme.accent

    // No `Behavior` here deliberately: this expression depends on
    // `_glowOpacity`, which is itself continuously driven by the breathing
    // SequentialAnimation below. Behavior + a binding with an
    // animator-driven dependency freezes the binding after its first
    // evaluation in this Qt Quick version -- the border got stuck on
    // whatever accent existed at startup (the violet dark-theme fallback,
    // before the adaptive wallpaper extraction finished) and never
    // tracked Theme.accent again. The breathing pulse still animates
    // smoothly via _glowOpacity's own animation; only a hue change
    // (wallpaper/theme switch) now snaps instead of crossfading.
    property color _borderColor: Qt.alpha(root._glowColor, root._glowOpacity)

    property real _glowOpacity: 0.35
    Behavior on _glowOpacity { NumberAnimation { duration: 1500; easing.type: Easing.InOutSine } }

    SequentialAnimation on _glowOpacity {
        running: root.glow
        loops: Animation.Infinite
        NumberAnimation { to: 0.65; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.28; duration: 1600; easing.type: Easing.InOutSine }
    }

    Behavior on color { ColorAnimation { duration: Theme.animSlow } }
}
