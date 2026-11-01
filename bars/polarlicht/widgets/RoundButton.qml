import QtQuick
import qs

Rectangle {
    id: root
    property string icon: ""
    property real size: 34
    property bool accent: false
    signal clicked()
    width: size; height: size; radius: size / 2
    color: accent ? Theme.accent : ma.containsMouse ? Theme.surfaceHi : Theme.surface
    scale: ma.pressed ? 0.88 : 1
    Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }
    Glyph { anchors.centerIn: parent; text: root.icon; size: root.size * 0.48; color: root.accent ? Theme.onAccent : Theme.text }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
