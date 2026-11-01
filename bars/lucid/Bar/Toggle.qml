import QtQuick
import "../"

// Small pill switch for enable/disable rows (Wi-Fi, Bluetooth adapter).
// Same no-QtQuick.Controls house style as TextField.qml/Slider.qml.
Item {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled(bool checked)

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceVariant
        opacity: root.enabled ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Rectangle {
            width: parent.height - 4
            height: parent.height - 4
            radius: width / 2
            color: root.checked ? Theme.primaryInk : Theme.outline
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: Theme.durBase; easing.type: Theme.easeOut } }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
