import QtQuick
import "../"

// Interactive capsule surface (radius = height/2, no border).
// Hover raises the tone + scales 1.04, press squashes to 0.96.
// Put content inside; it is laid out in a centered Row.
Item {
    id: root

    property color color: Theme.surface
    property color hoverColor: Theme.surfaceHover
    property bool interactive: true
    property bool flat: false          // no fill until hovered
    property real padding: Theme.s3
    property alias spacing: row.spacing
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property int acceptedButtons: Qt.LeftButton
    default property alias content: row.data

    signal clicked(var mouse)
    signal wheel(var event)

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + padding * 2

    scale: !interactive ? 1 : mouse.pressed ? Theme.pressScale : mouse.containsMouse ? Theme.hoverScale : 1
    Behavior on scale {
        NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: root.interactive && mouse.containsMouse ? root.hoverColor : root.flat ? Theme.alpha(root.color, 0) : root.color
        Behavior on color {
            ColorAnimation { duration: Theme.tFast; easing.type: Theme.easeOut }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: root.acceptedButtons
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => root.clicked(m)
        onWheel: e => root.wheel(e)
    }
}
