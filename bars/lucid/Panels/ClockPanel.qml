import QtQuick
import "../"

Flickable {
    id: root
    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: layout
        width: root.width
        spacing: 14
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        CalendarGrid {}

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        WeatherRow { width: parent.width - 28 }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        ReminderList { width: parent.width - 28 }
    }
}
