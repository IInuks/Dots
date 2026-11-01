import QtQuick

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 26

    signal clicked()

    property bool hovered: false

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceAlt
        opacity: root.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Icon {
        anchors.centerIn: parent
        name: "power"
        size: 15
        tint: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
