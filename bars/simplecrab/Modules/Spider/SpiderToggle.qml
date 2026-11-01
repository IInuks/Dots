import QtQuick
import "../.."

// Kleiner An/Aus-Schalter, gleiches Farbschema wie der Rest der Bar.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    width: 40
    height: 22
    radius: height / 2
    color: root.checked ? Colors.accent : Colors.panelAlt
    border.color: Colors.divider
    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        color: Colors.accentInk
        y: 2
        x: root.checked ? root.width - width - 2 : 2

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
