import QtQuick
import "../../"

// Calendar dropdown content (menus prompt 1.4), opened from the clock.
// Month paging slides the grid out (±90px, fade, 180ms) then back in from
// the other side -- no real event backend exists, so CalendarCell's
// `hasEvent` dot is always off; the grid logic doesn't special-case that.
Column {
    id: root
    spacing: 8
    width: Style.dropdownMinWidth - 24

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() // 0-based

    function _go(delta) {
        let m = root.viewMonth + delta;
        let y = root.viewYear;
        if (m < 0) { m = 11; y -= 1; }
        else if (m > 11) { m = 0; y += 1; }
        slideOut.direction = delta;
        slideOut.start();
        // Model update happens once the outgoing slide/fade finishes, in
        // onStopped below, then slideIn plays.
        slideOut._pendingYear = y;
        slideOut._pendingMonth = m;
    }

    readonly property var _cells: {
        const first = new Date(root.viewYear, root.viewMonth, 1);
        const startOffset = (first.getDay() + 6) % 7; // Mon-first
        const daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate();
        const today = new Date();
        const isCurrentMonth = today.getFullYear() === root.viewYear && today.getMonth() === root.viewMonth;

        const cells = [];
        for (let i = 0; i < startOffset; i++)
            cells.push({ day: 0, isToday: false });
        for (let d = 1; d <= daysInMonth; d++)
            cells.push({ day: d, isToday: isCurrentMonth && d === today.getDate() });
        while (cells.length < 42)
            cells.push({ day: 0, isToday: false });
        return cells;
    }

    // -- Header: prev/next + "MMMM YYYY" -------------------------------
    Item {
        width: parent.width
        height: 18

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: "\u{F004D}"
            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root._go(-1) }
        }
        Text {
            anchors.centerIn: parent
            font.family: Style.textFont
            font.pixelSize: 14
            color: Colors.primary
            text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy").toUpperCase()
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: "\u{F0054}"
            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root._go(1) }
        }
    }

    // -- Weekday row + day grid, both inside the sliding container -----
    Item {
        id: slideArea
        width: parent.width
        height: gridColumn.height
        clip: true

        Column {
            id: gridColumn
            width: parent.width
            spacing: 4

            Grid {
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    Text {
                        width: 28
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Style.textFont
                        font.pixelSize: 11
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)
                        text: modelData
                    }
                }
            }

            Grid {
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: root._cells
                    CalendarCell {
                        day: modelData.day
                        isToday: modelData.isToday
                    }
                }
            }
        }

        SequentialAnimation {
            id: slideOut
            property int direction: 1
            property int _pendingYear: root.viewYear
            property int _pendingMonth: root.viewMonth

            ParallelAnimation {
                NumberAnimation { target: gridColumn; property: "x"; to: -slideOut.direction * 90; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: gridColumn; property: "opacity"; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }
            ScriptAction {
                script: {
                    root.viewYear = slideOut._pendingYear;
                    root.viewMonth = slideOut._pendingMonth;
                    gridColumn.x = slideOut.direction * 90;
                }
            }
            ParallelAnimation {
                NumberAnimation { target: gridColumn; property: "x"; to: 0; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: gridColumn; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }
}
