import QtQuick

Item {
    id: root
    property string label: ""
    property bool active: false
    signal activated()

    implicitWidth: text.implicitWidth + 4
    implicitHeight: 40

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: 12
        color: root.active ? Theme.text : Theme.textDim
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
