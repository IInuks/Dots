import QtQuick
import qs

// Schnellschalter-Kachel
Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    signal clicked()

    implicitHeight: 58
    radius: 18
    color: on ? Theme.accent : ma.containsMouse ? Theme.surfaceHi : Theme.surface
    scale: ma.pressed ? 0.95 : 1
    Behavior on color { ColorAnimation { duration: Theme.dur(240) } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutBack } }

    Row {
        anchors.left: parent.left; anchors.leftMargin: 14
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 11
        Rectangle {
            width: 32; height: 32; radius: 16
            anchors.verticalCenter: parent.verticalCenter
            color: root.on ? Qt.rgba(0, 0, 0, 0.12) : Theme.accentSoft
            Glyph {
                anchors.centerIn: parent; text: root.icon; size: 17
                color: root.on ? Theme.onAccent : Theme.accent
                rotation: root.on ? 360 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.dur(600); easing.type: Easing.OutBack } }
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 43
            Txt { width: parent.width; text: root.label; font.weight: Font.DemiBold; color: root.on ? Theme.onAccent : Theme.text }
            Txt { width: parent.width; text: root.sub; font.pixelSize: 11; visible: text !== ""; color: root.on ? Theme.onAccent : Theme.textDim; opacity: 0.85 }
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
