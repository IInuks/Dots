import QtQuick

// Ein runder/pillenförmiger Knopf mit Hover-Schimmer und Drück-Federung.
Rectangle {
    id: k
    property bool active: false
    property bool hoverable: true
    property color tint: Theme.accent
    property alias hovered: ma.containsMouse
    property alias pressed: ma.pressed
    property int cursor: Qt.PointingHandCursor
    signal clicked(var mouse)
    signal wheel(var wheel)

    radius: Math.min(height / 2, Theme.radius)
    color: active ? Theme.alpha(tint, 0.22)
         : (ma.containsMouse && hoverable ? Theme.alpha(Theme.text, 0.08) : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.tFast } }

    scale: ma.pressed ? 0.93 : 1
    Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: k.cursor
        onClicked: m => k.clicked(m)
        onWheel: w => k.wheel(w)
    }
}
