import QtQuick
import Quickshell

PopupCard {
    id: popup
    popupId: "calendar"
    edge: "center"
    popupWidth: 260

    property date _today: new Date()
    property date _viewDate: new Date()
    SystemClock { id: liveClock; precision: SystemClock.Minutes; onDateChanged: popup._today = liveClock.date }

    function _startOfMonth(d) { return new Date(d.getFullYear(), d.getMonth(), 1); }
    function _daysInMonth(d) { return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); }
    // Monday-first weekday index: JS getDay() is 0=Sun..6=Sat.
    function _mondayIndex(d) { return (d.getDay() + 6) % 7; }
    function _isSameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }

    readonly property var _cells: {
        const first = _startOfMonth(_viewDate);
        const lead = _mondayIndex(first);
        const total = _daysInMonth(_viewDate);
        const cells = [];
        for (let i = 0; i < lead; i++) cells.push(null);
        for (let day = 1; day <= total; day++) cells.push(day);
        return cells;
    }

    Column {
        spacing: 4
        width: parent.width
        Text {
            text: Qt.formatTime(popup._today, "hh:mm")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeClock
            color: Theme.foreground
        }
        Text {
            text: Qt.formatDate(popup._today, "dddd, d. MMMM yyyy")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.muted
        }
    }

    Row {
        width: parent.width
        Text {
            width: parent.width - 60
            text: Qt.formatDate(popup._viewDate, "MMMM yyyy")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            color: Theme.foreground
            verticalAlignment: Text.AlignVCenter
            height: 28
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup._viewDate = new Date() }
        }
        Row {
            spacing: 4
            NavArrow { symbol: "‹"; onClicked: popup._viewDate = new Date(popup._viewDate.getFullYear(), popup._viewDate.getMonth() - 1, 1) }
            NavArrow { symbol: "›"; onClicked: popup._viewDate = new Date(popup._viewDate.getFullYear(), popup._viewDate.getMonth() + 1, 1) }
        }
    }

    Grid {
        id: dayGrid
        columns: 7
        columnSpacing: 2
        rowSpacing: 4
        width: parent.width

        Repeater {
            model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
            delegate: Text {
                required property string modelData
                width: dayGrid.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.muted
            }
        }

        Repeater {
            model: popup._cells
            delegate: Item {
                required property var modelData
                readonly property bool isToday: modelData !== null && popup._isSameDay(new Date(popup._viewDate.getFullYear(), popup._viewDate.getMonth(), modelData), popup._today)
                width: dayGrid.width / 7
                height: 26

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    visible: parent.isToday
                    color: Theme.activeFill
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: parent.isToday ? Theme.background : Theme.foreground
                }
            }
        }
    }
}
