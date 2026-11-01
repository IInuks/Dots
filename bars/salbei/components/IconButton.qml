import QtQuick
import "../"

// Small rounded-square (or round) icon button. Fades its hover wash, springs on press.
Rectangle {
    id: root

    property string icon
    property real iconSize: Theme.iconBar
    property bool round: false
    property bool active: false
    property bool filled: true            // show the tile background when idle
    property color iconColor: active ? Theme.accentInk : Theme.text
    readonly property bool hovered: mouse.containsMouse
    property alias iconItem: glyph

    signal clicked
    signal rightClicked
    signal wheel(int delta)

    implicitWidth: 28
    implicitHeight: 28
    radius: round ? height / 2 : Theme.radiusIconButton
    color: active ? Theme.accent : (filled ? Theme.tile : "transparent")
    scale: mouse.pressed ? Theme.pressScale : 1

    Behavior on color { ColorAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 4 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.hover
        opacity: mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: e => root.wheel(e.angleDelta.y)
    }
}
