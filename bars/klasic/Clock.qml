import QtQuick
import Quickshell

Rectangle {
    id: root
    signal clicked()
    property bool open: false

    width: label.implicitWidth + 14
    height: 22
    radius: Theme.radiusSmall
    color: (open || hoverArea.containsMouse) ? Qt.alpha(Theme.text, 0.1) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: true
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.pixelSize: 12
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
