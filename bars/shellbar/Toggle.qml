import QtQuick

// Small reusable on/off switch used throughout the settings menu.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    width: 34
    height: 18
    radius: 9
    color: checked ? Theme.accent : Qt.alpha(Theme.mutedText, 0.3)
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: "#1a1a1a"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 2 : 2
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
