import QtQuick
import "../.."

// Device-style edge: a light 1-2px line top/left, a dark one bottom/right.
// No blur, no drop shadow -- just the four static strips, cached as one
// texture since none of them ever move on their own (only their two colors
// crossfade on a palette swap).
Item {
    id: root

    property int bevel: Theme.bevelWidth
    property color light: Theme.bevelLight
    property color dark: Theme.bevelDark

    layer.enabled: true
    layer.samples: 4

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bevel
        color: root.light
    }
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.bevel
        color: root.light
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bevel
        color: root.dark
    }
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.bevel
        color: root.dark
    }
}
