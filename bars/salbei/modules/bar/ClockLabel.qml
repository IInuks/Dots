import QtQuick
import Quickshell
import "../../"
import "../../components"
import "../../services"

// "10:00 AM   05 Oct 26" — click opens the calendar popup. Digits roll on change.
Item {
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.barSpacing
        scale: mouse.pressed ? 0.94 : mouse.containsMouse ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }

        RollingText {
            text: Qt.formatDateTime(clock.date, WidgetSettings.clock24h ? "HH:mm" : "hh:mm AP")
            pixelSize: Theme.fontBar
            weight: Font.Normal
            color: Ui.calendarOpen ? Theme.accent : Theme.text
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }
        RollingText {
            text: Qt.formatDateTime(clock.date, "dd MMM yy")
            pixelSize: Theme.fontBar
            weight: Font.Normal
            color: Ui.calendarOpen ? Theme.accent : Theme.text
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.toggleCalendar()
    }
}
