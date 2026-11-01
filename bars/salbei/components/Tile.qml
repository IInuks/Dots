import QtQuick
import "../"

// Card inside a panel. With `interactive` it reacts to hover and emits clicked().
// Every tile rises into place when created; `order` staggers tiles of one page.
Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property bool available: true
    property int order: 0
    readonly property bool hovered: mouse.containsMouse
    readonly property color fg: active ? Theme.accentInk : Theme.text

    signal clicked
    signal rightClicked

    radius: Theme.radiusTile
    color: active ? Theme.tileActive : Theme.tile
    opacity: (available ? 1 : 0.45) * appear

    Behavior on color { ColorAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

    // ── entrance ──
    property real appear: 0
    function replay() { appear = 0; enter.restart(); }
    transform: Translate { y: (1 - root.appear) * 14 }
    scale: (0.94 + 0.06 * appear) * (mouse.pressed && root.interactive && root.available ? 0.97 : 1)
    Behavior on scale { enabled: root.appear >= 1; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
    SequentialAnimation {
        id: enter
        running: true
        PauseAnimation { duration: Math.max(0, Math.min(root.order, Theme.staggerMax)) * Theme.animStagger * 1.6 }
        NumberAnimation { target: root; property: "appear"; to: 1; duration: Theme.animSlow; easing.type: Theme.easingEmph }
    }

    // ── state flash when toggled on ──
    onActiveChanged: if (appear >= 1) flash.restart()
    Rectangle {
        id: ring
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: parent.radius
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: 0
    }
    ParallelAnimation {
        id: flash
        NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 520; easing.type: Easing.OutQuad }
        NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.12; duration: 520; easing.type: Theme.easingEmph }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.hover
        opacity: root.interactive && root.available && mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.interactive && root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: e => {
            if (!root.available) return;
            if (e.button === Qt.RightButton) root.rightClicked();
            else root.clicked();
        }
    }
}
