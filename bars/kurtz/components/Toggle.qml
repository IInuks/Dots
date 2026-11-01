import QtQuick
import "../"

// Capsule switch with an Orb knob that rolls across (and squashes on the
// bounce). Off = muted grey-blue orb, on = accent orb + glow.
Item {
    id: root
    property bool checked: false
    property color color: Theme.accent
    signal toggled(bool v)

    implicitWidth: 46
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.alpha(root.color, 0.28) : Theme.surfaceSunken
        Behavior on color { ColorAnimation { duration: Theme.tMed } }
    }
    Orb {
        width: root.height - 6
        height: width
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? root.color : Theme.textFaint
        glowing: root.checked
        glowStrength: 0.6
        Behavior on x { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
