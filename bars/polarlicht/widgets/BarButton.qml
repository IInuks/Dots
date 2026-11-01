import QtQuick
import qs

// Pillenförmiger Knopf in einer Insel; "active" hebt ihn in Akzentfarbe hervor.
Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    property real iconSize: 16
    property color fg: active ? Theme.onAccent : Theme.text
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitHeight: 30
    implicitWidth: row.implicitWidth + (label !== "" ? 22 : 14)
    radius: height / 2
    color: active ? Theme.accent : ma.containsMouse ? Theme.surfaceHi : "transparent"
    scale: ma.pressed ? 0.9 : 1

    Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Glyph { text: root.icon; size: root.iconSize; color: root.fg; visible: root.icon !== ""; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: root.label; color: root.fg; font.weight: Font.DemiBold; visible: root.label !== ""; anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
    }
}
