import QtQuick
import ".."

// Round glass button with a Nerd Font glyph and a hover label.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property color tint: Theme.text
    property int size: 44
    // hover label below instead of above (for buttons at the top edge)
    property bool labelBelow: false
    signal clicked()

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: width / 2
        color: mouse.containsMouse ? Theme.hover : Theme.panel
        border.color: mouse.containsMouse ? Qt.alpha(root.tint, 0.5) : Theme.border
        border.width: 1
        scale: mouse.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: root.size * 0.42
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.labelBelow ? parent.height + Theme.spacingS : -height - Theme.spacingS
        text: root.label
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontS
        opacity: mouse.containsMouse && root.label !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
