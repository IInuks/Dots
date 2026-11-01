import QtQuick

// Kippschalter; der Knubbel ist ein kleines Ei.
Rectangle {
    id: t
    property bool on: false
    signal toggled(bool v)
    width: 44; height: 24; radius: 12
    color: on ? Theme.accent : Theme.surface3
    Behavior on color { ColorAnimation { duration: Theme.tMed } }
    EggShape {
        width: 16; height: 20
        y: 2
        x: t.on ? t.width - width - 4 : 4
        fill: t.on ? Theme.text : Theme.textDim
        shine: false
        Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled(!t.on)
    }
}
