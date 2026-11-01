import QtQuick

// A single row-style action inside a drop-menu: optional icon + label,
// hover highlight, click signal. Reused by the power menu and (later)
// other simple list-style menus.
Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property color tint: Theme.text
    signal activated()

    width: parent ? parent.width : 180
    height: 34
    radius: Theme.radiusSmall
    color: hover.hovered ? Theme.surfaceAlt : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Icon {
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: 14
            tint: root.tint
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.tint
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
