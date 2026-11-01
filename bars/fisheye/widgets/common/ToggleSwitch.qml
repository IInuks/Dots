import QtQuick
import "../.."

// Shared on/off switch (Wi-Fi enable, Bluetooth adapter enable, ...).
// `checked` is bindable from outside; toggled(bool) is what callers act on
// -- this widget never assumes it owns the underlying state, same split
// SegmentSlider uses for value/moved.
Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 34
    implicitHeight: 16

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.bevelDark
        Behavior on color {
            ColorAnimation {
                duration: Theme.durFast
            }
        }
    }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 2 : 2
        color: root.checked ? Theme.accentInk : Theme.surfaceInk
        Behavior on x {
            NumberAnimation {
                duration: Theme.durFast
                easing.type: Theme.easeOut
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
