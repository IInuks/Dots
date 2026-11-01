import QtQuick
import "../"

// Small selectable capsule (segmented choices, device lists, buttons).
// selected = accent fill with a tiny orb on the left.
Rectangle {
    id: root
    property string text
    property string glyph: ""
    property bool selected: false
    property color tint: Theme.accent
    signal clicked

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 24
    radius: height / 2
    color: selected ? Theme.alpha(tint, 0.22) : mouse.containsMouse ? Theme.surfaceHover : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.tFast } }

    scale: mouse.pressed ? Theme.pressScale : mouse.containsMouse ? Theme.hoverScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: Theme.popOvershoot } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Orb {
            visible: root.selected
            anchors.verticalCenter: parent.verticalCenter
            width: 10; height: 10
            color: root.tint
            rim: false
        }
        KIcon {
            visible: root.glyph !== "" && !root.selected
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            size: 14
            color: root.tint
        }
        KLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: Theme.fSmall + 1
            color: root.selected ? Theme.text : Theme.textMuted
            width: Math.min(implicitWidth, 200)
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
