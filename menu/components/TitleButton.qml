import QtQuick
import ".."

// Minimize / maximize / close button in the title bar.
Rectangle {
    id: btn

    property string icon: ""
    property color hoverColor: Theme.panelAlt
    property color hoverIconColor: Theme.text
    signal clicked()

    width: 30
    height: 24
    radius: 6
    color: mouse.containsMouse ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Icon {
        anchors.centerIn: parent
        text: btn.icon
        size: Theme.fontS
        color: mouse.containsMouse ? btn.hoverIconColor : Theme.textDim
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
