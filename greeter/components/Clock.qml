import QtQuick
import Quickshell
import ".."

Column {
    id: root
    spacing: -Theme.spacingS

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontClock
        font.weight: Font.Light
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.25)
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.locale().toString(clock.date, "dddd, d. MMMM")
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontL
        font.letterSpacing: 1
    }
}
