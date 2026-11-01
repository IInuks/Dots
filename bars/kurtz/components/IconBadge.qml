import QtQuick
import "../"

// Flat glyph in a circular badge.
//   inactive: flat surface circle, muted glyph
//   active:   shaded accent Orb + soft glow, dark glyph
// Optional `count` shows a small magenta orb with a number (bell etc.).
Item {
    id: root

    property string glyph: Glyphs.star4
    property bool active: false
    property color color: Theme.accent
    property real glyphScale: 0.5
    property int count: 0
    property bool interactive: true
    property alias hovered: mouse.containsMouse
    property int acceptedButtons: Qt.LeftButton
    property real bump: 0 // animate this to "pop" the badge

    signal clicked(var mouse)
    signal wheel(var event)

    implicitWidth: Theme.pillHeight
    implicitHeight: Theme.pillHeight

    scale: (mouse.pressed ? Theme.pressScale : mouse.containsMouse ? 1.08 : 1) + bump
    Behavior on scale {
        NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
        opacity: root.active ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        Behavior on color { ColorAnimation { duration: Theme.tFast } }
    }

    Orb {
        anchors.fill: parent
        color: root.color
        glowing: root.active
        glowStrength: 0.8
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot } }
    }

    KIcon {
        anchors.centerIn: parent
        text: root.glyph
        size: root.width * root.glyphScale
        color: root.active ? Theme.shadeOf(Theme.shadeOf(root.color)) : mouse.containsMouse ? Theme.text : Theme.textMuted
        Behavior on color { ColorAnimation { duration: Theme.tMed } }
    }

    // count bubble
    Orb {
        visible: root.count > 0
        width: Math.max(14, root.width * 0.42)
        height: width
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -3
        anchors.topMargin: -3
        color: Theme.magenta
        rim: false
        highlight: false
        glowing: true
        glowStrength: 0.6
        KLabel {
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : root.count
            font.pixelSize: parent.width * 0.62
            font.weight: Font.Bold
            color: Theme.bgTop
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: root.acceptedButtons
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
        onWheel: e => root.wheel(e)
    }
}
