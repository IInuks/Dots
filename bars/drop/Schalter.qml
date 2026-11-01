import QtQuick

// Schalter: der Tropfen darin fließt hinüber und zieht sich dabei in die
// Länge, wie ein Tropfen, der über Glas rinnt.
Item {
    id: t
    property bool checked: false
    signal toggled()
    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: t.checked ? Theme.alpha(Theme.accent, 0.35) : Theme.surface3
        Behavior on color { ColorAnimation { duration: Theme.tMed } }
    }
    Rectangle {
        id: knob
        property real stretch: 0
        width: 16 + stretch
        height: 16 - stretch * 0.25
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: t.checked ? t.width - width - 4 : 4
        color: t.checked ? Theme.accent : Theme.textDim
        Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on color { ColorAnimation { duration: Theme.tMed } }
        SequentialAnimation {
            id: stretchAnim
            NumberAnimation { target: knob; property: "stretch"; to: 10; duration: Theme.ms(110); easing.type: Easing.OutQuad }
            SpringAnimation { target: knob; property: "stretch"; to: 0; spring: 6; damping: 0.18 }
        }
    }
    onCheckedChanged: if (Theme.motion) stretchAnim.restart()
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled()
    }
}
