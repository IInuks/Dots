import QtQuick
import qs

Rectangle {
    id: root
    property real value: 0
    property color barColor: Theme.accent
    implicitHeight: 6
    radius: height / 2
    color: Theme.surfaceHi
    Rectangle {
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
        height: parent.height; radius: parent.radius
        color: root.barColor
        Behavior on width { NumberAnimation { duration: Theme.dur(500); easing.type: Easing.OutCubic } }
    }
}
