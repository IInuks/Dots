import QtQuick
import ".."

// Small on/off switch, ported from shellbar/Toggle.qml, monochrome (no
// Theme.accent in this bar's palette -- "on" just uses the bright text
// color instead of a color accent).
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    width: 30
    height: 16
    radius: 8
    color: checked ? Theme.text : Qt.alpha(Theme.textMuted, 0.3)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Rectangle {
        width: 12
        height: 12
        radius: 6
        color: Theme.background
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 2 : 2
        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
