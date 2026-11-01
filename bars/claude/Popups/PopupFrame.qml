import QtQuick
import ".."

// Shared chrome for every flyout: a panel of the caller's own size,
// horizontally centered on Popups.anchorX (clamped to stay on-screen) and
// dropping down out of the dock rather than the single fixed Command-Center
// panel this shell deliberately avoids.
Item {
    id: root

    default property alias content: body.data
    property alias panelWidth: body.width
    property alias panelHeight: body.height
    property real screenWidth: 1920

    // Driven from outside (one PopupFrame instance per popup id, always
    // alive, so the fade-out on close gets to finish instead of being cut
    // off by a Loader tearing the content down mid-animation).
    property bool shown: false
    visible: root.opacity > 0.001
    property real _riseOffset: root.shown ? 0 : Metrics.popupSlideDistance
    Behavior on _riseOffset { SpringAnimation { spring: 3; damping: 0.42 } }

    anchors.top: parent.top
    anchors.topMargin: Metrics.barHeight + 12 - root._riseOffset
    width: body.width
    height: body.height

    readonly property real _rawX: Popups.anchorX - body.width / 2
    x: Math.max(10, Math.min(root._rawX, root.screenWidth - body.width - 10))

    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.92
    Behavior on opacity { NumberAnimation { duration: Metrics.popupAnimMs; easing.type: Easing.OutCubic } }
    Behavior on scale { SpringAnimation { spring: 3; damping: 0.4 } }
    Behavior on x { SpringAnimation { spring: 2.6; damping: 0.45 } }

    Rectangle {
        id: body
        radius: Chroma.rMed
        color: Chroma.panel
        border.width: 1
        border.color: Qt.alpha(Chroma.accent, 0.28)

        // absorb clicks so they never reach the full-screen backdrop
        MouseArea { anchors.fill: parent; onClicked: {} }
    }
}
