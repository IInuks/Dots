import QtQuick
import "../../"

// Shared dropdown chrome (menus prompt section 1, "Alle Dropdowns haben
// dieses gemeinsame Gerüst"): fixed 320px width, surface background (0.88,
// 0.92 for the notification center), height animates 0 -> content+24 on a
// BezierSpline, a primary accent line grows under it (classic style only --
// pill is deferred, see README), and the content itself only fades/slides
// in once the panel is past half-open so it doesn't pop in ahead of its own
// container.
//
// `open` and `contentHeight` are driven by the caller; `menuContent` is the
// actual dropdown body (a Loader'd XxxDropdown.qml), default-parented here
// so call sites can just write `Dropdown { open: ...; MyContent {} }`.
Item {
    id: root

    default property alias menuContent: contentSlot.children
    property bool open: false
    property real alpha: Style.islandAlpha
    property bool accentLine: true

    readonly property int _innerWidth: Style.dropdownMinWidth - 24
    readonly property real _contentHeight: contentSlot.childrenRect.height
    readonly property real _targetHeight: root.open ? (root._contentHeight + 24) : 0
    readonly property bool _revealed: root.open && root.height > root._targetHeight * 0.5

    width: Style.dropdownMinWidth
    height: root._targetHeight
    clip: true
    visible: height > 0.5

    Behavior on height {
        NumberAnimation {
            duration: Style.dropdownHeightMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.dropdownBezier
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, root.alpha)
    }

    // Bottom accent line: width 0 -> full in 300ms OutCubic once open.
    Rectangle {
        id: accent
        visible: root.accentLine
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        height: 2
        color: Colors.primary
        width: root.open ? root.width : 0
        Behavior on width {
            NumberAnimation { duration: Style.dropdownLineMs; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: contentSlot
        x: 12
        width: root._innerWidth
        height: childrenRect.height
        // y tracks the panel's own (already-animated) height directly --
        // no separate Behavior here, or the two animations would fight and
        // lag the content a frame behind the panel edge it's anchored to.
        // Only the reveal offset (translate -15 -> 0) gets its own tween.
        y: root.height - contentSlot.height - 12
        opacity: root._revealed ? 1 : 0

        transform: Translate {
            y: root._revealed ? 0 : -15
            Behavior on y { NumberAnimation { duration: Style.dropdownContentMs; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: Style.dropdownContentMs; easing.type: Easing.OutCubic } }
    }
}
