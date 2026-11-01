import QtQuick
import Quickshell
import "../../"
import "../../components"

// Month view under the bar clock.
GlassPanel {
    id: root

    namespace: "qs-calendar"
    open: Ui.calendarOpen
    placement: "top"
    panelWidth: 300
    panelHeight: grid.implicitHeight + 2 * padding + header.height + 6
    radius: Theme.radiusTile
    onDismissed: Ui.calendarOpen = false
    onOpenChanged: if (open) grid.reset()

    SystemClock { id: clock; precision: SystemClock.Hours }

    Column {
        width: parent.width
        spacing: 6

        Row {
            id: header
            spacing: 8
            Txt { text: Qt.locale("en_US").toString(clock.date, "dddd"); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
            Txt { text: Qt.formatDate(clock.date, "yyyy-MM-dd"); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
        }
        MonthGrid {
            id: grid
            width: parent.width
            today: clock.date
            cell: 33
        }
    }
}
