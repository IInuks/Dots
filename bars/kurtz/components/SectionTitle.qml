import QtQuick
import "../"

// Tiny spaced caps heading with a little accent dot and a dotted rule.
Item {
    id: root
    property string text
    property color color: Theme.accent
    implicitHeight: 18
    implicitWidth: 200

    Rectangle {
        id: dot
        width: 6
        height: 6
        radius: 3
        color: root.color
        anchors.verticalCenter: parent.verticalCenter
    }
    KLabel {
        id: lbl
        anchors.left: dot.right
        anchors.leftMargin: Theme.s2
        anchors.verticalCenter: parent.verticalCenter
        role: "caps"
        text: root.text
    }
    // dotted separator
    Row {
        anchors.left: lbl.right
        anchors.leftMargin: Theme.s2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        clip: true
        Repeater {
            model: Math.max(0, Math.floor((root.width - lbl.width - 30) / 7))
            Rectangle { width: 2; height: 2; radius: 1; color: Theme.textFaint; opacity: 0.6 }
        }
    }
}
