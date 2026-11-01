import QtQuick

Item {
    id: root
    implicitWidth: label.implicitWidth + (dot.visible ? 10 : 0)
    implicitHeight: 22

    signal clicked()

    property bool hovered: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: label.text = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: Theme.radiusSmall
        color: Theme.surfaceAlt
        opacity: root.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.pixelSize: 13
        }

        Rectangle {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: Theme.accent2
            visible: NotificationState.unreadCount > 0
            scale: visible ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
