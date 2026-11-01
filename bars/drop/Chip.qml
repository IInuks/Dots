import QtQuick

// Auswahl-Pille. Ausgewählt = mit Akzent gefüllt.
Rectangle {
    id: c
    property string text: ""
    property string icon: ""
    property bool selected: false
    property color swatch: "transparent"
    signal clicked()

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 30
    radius: height / 2
    color: selected ? Theme.accent : (ma.containsMouse ? Theme.alpha(Theme.text, 0.09) : Theme.alpha(Theme.text, 0.05))
    border.width: 1
    border.color: selected ? "transparent" : Theme.line
    scale: ma.pressed ? 0.94 : 1
    Behavior on color { ColorAnimation { duration: Theme.tFast } }
    Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: c.swatch.a > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 12; height: 12; radius: 6
            color: c.swatch
            border.width: 1; border.color: Theme.alpha(Theme.text, 0.3)
        }
        Icon {
            visible: c.icon.length > 0
            anchors.verticalCenter: parent.verticalCenter
            name: c.icon; size: 14
            color: c.selected ? Theme.accentInk : Theme.text
        }
        Label {
            visible: c.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: c.text; size: 12.5; bold: c.selected
            color: c.selected ? Theme.accentInk : Theme.text
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: c.clicked()
    }
}
