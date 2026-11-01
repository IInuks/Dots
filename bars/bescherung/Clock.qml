import QtQuick
import Quickshell

Row {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale("de_DE").toString(clock.date, "ddd d. MMMM")
        font.family: Theme.font
        font.pixelSize: Theme.textSize
        font.weight: Font.DemiBold
        color: Theme.inkSoft
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        font.family: Theme.font
        font.pixelSize: Theme.textSize + 3
        font.weight: Font.Bold
        color: Theme.ink
    }
}
