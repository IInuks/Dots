import QtQuick
import "../"

// Compact month view, today highlighted. No date-picking interaction --
// the spec only asked for a calendar to look at, not a scheduler.
Column {
    id: root
    spacing: 6

    readonly property var _cells: _buildCells(Clock.now)

    function _buildCells(now) {
        const year = now.getFullYear();
        const month = now.getMonth();
        const today = now.getDate();
        const firstOfMonth = new Date(year, month, 1);
        // JS getDay(): 0=Sun..6=Sat -> convert to Mon-first (0=Mon..6=Sun).
        const startOffset = (firstOfMonth.getDay() + 6) % 7;
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        const cells = [];
        for (let i = 0; i < startOffset; i++)
            cells.push({ day: 0, isToday: false });
        for (let d = 1; d <= daysInMonth; d++)
            cells.push({ day: d, isToday: d === today });
        while (cells.length % 7 !== 0)
            cells.push({ day: 0, isToday: false });
        return cells;
    }

    Text {
        text: Clock.formatDate("MMMM yyyy")
        color: Theme.surfaceInk
        font.pixelSize: 14
        font.bold: true
        font.family: Theme.uiFontFamily
    }

    Grid {
        columns: 7
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
            Text {
                width: 26
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.outline
                font.pixelSize: 10
                font.family: Theme.uiFontFamily
            }
        }

        Repeater {
            model: root._cells
            Rectangle {
                width: 26
                height: 22
                radius: 6
                color: modelData.isToday ? Theme.primary : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: modelData.day > 0 ? modelData.day : ""
                    color: modelData.isToday ? Theme.primaryInk : Theme.surfaceInk
                    font.pixelSize: 11
                    font.family: Theme.uiFontFamily
                }
            }
        }
    }
}
