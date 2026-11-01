import QtQuick

// A small pill switch used for the transparency toggle in SettingsPopup.
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.activeFill : Qt.alpha(Theme.foreground, 0.18)
        Behavior on color { ColorAnimation { duration: Theme.animSoft } }
    }

    Rectangle {
        id: knob
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        color: Theme.background
        Behavior on x { NumberAnimation { duration: Theme.animSoft; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
