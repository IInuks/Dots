import QtQuick
import "../"

// Quick-toggle tile: rounded card with an IconBadge, a label and a muted
// state line. Active = raised surface + accent orb badge with glow.
Rectangle {
    id: root
    property string glyph
    property string label
    property string sub: ""
    property bool active: false
    property color accent: Theme.accent
    signal clicked

    implicitHeight: 58
    implicitWidth: 150
    radius: Theme.rMed
    color: mouse.containsMouse ? Theme.surfaceHover : active ? Theme.surfaceRaised : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.tFast } }

    scale: mouse.pressed ? Theme.pressScale : mouse.containsMouse ? 1.02 : 1
    Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot } }

    IconBadge {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: Theme.s2 + 2
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        glyph: root.glyph
        active: root.active
        color: root.accent
        interactive: false
    }
    Column {
        anchors.left: badge.right
        anchors.leftMargin: Theme.s2 + 2
        anchors.right: parent.right
        anchors.rightMargin: Theme.s2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        KLabel {
            width: parent.width
            text: root.label
            font.weight: Font.DemiBold
        }
        KLabel {
            width: parent.width
            role: "muted"
            text: root.sub !== "" ? root.sub : root.active ? "An" : "Aus"
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
