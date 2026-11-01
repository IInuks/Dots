pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.widgets

MenuCard {
    id: root
    name: "calendar"
    width: 380
    height: col.implicitHeight + 40

    SystemClock { id: clock; precision: root.open ? SystemClock.Seconds : SystemClock.Hours }

    property int monthOffset: 0
    property int slideDir: 1
    onOpenChanged: if (open) monthOffset = 0

    readonly property var shown: {
        const d = new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)
        return { y: d.getFullYear(), m: d.getMonth() }
    }
    readonly property var cells: {
        const first = new Date(shown.y, shown.m, 1)
        const lead = (first.getDay() + 6) % 7          // Montag zuerst
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(shown.y, shown.m, 1 - lead + i)
            out.push({ day: d.getDate(), inMonth: d.getMonth() === shown.m,
                       today: d.toDateString() === clock.date.toDateString(),
                       weekend: d.getDay() === 0 || d.getDay() === 6 })
        }
        return out
    }

    function shift(n) { slideDir = n; monthOffset += n; slide.restart() }

    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top; anchors.margins: 20
        spacing: 16

        // große Uhr
        Column {
            spacing: 2
            Row {
                spacing: 4
                Txt { text: Qt.formatDateTime(clock.date, "HH:mm"); font.pixelSize: 46; font.weight: Font.Bold; color: Theme.text }
                Txt { text: Qt.formatDateTime(clock.date, "ss"); font.pixelSize: 20; font.weight: Font.Bold; color: Theme.accent; anchors.baseline: parent.children[0].baseline }
            }
            Txt { text: Qt.locale("de_DE").toString(clock.date, "dddd, d. MMMM yyyy"); color: Theme.textDim }
        }

        // Fortschritt
        Column {
            width: parent.width; spacing: 6
            readonly property real dayP: (clock.date.getHours() * 3600 + clock.date.getMinutes() * 60 + clock.date.getSeconds()) / 86400
            readonly property real yearP: {
                const y = clock.date.getFullYear()
                return (clock.date - new Date(y, 0, 1)) / (new Date(y + 1, 0, 1) - new Date(y, 0, 1))
            }
            Row {
                width: parent.width
                Txt { width: parent.width / 2; text: "Tag  " + Math.round(parent.parent.dayP * 100) + "%"; font.pixelSize: 11; color: Theme.textDim }
                Txt { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: "Jahr  " + (parent.parent.yearP * 100).toFixed(1) + "%"; font.pixelSize: 11; color: Theme.textDim }
            }
            Row {
                width: parent.width; spacing: 8
                Meter { width: (parent.width - 8) / 2; value: parent.parent.dayP }
                Meter { width: (parent.width - 8) / 2; value: parent.parent.yearP; barColor: Theme.accent2 }
            }
        }

        // Monatskopf
        Item {
            width: parent.width; height: 34
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale("de_DE").standaloneMonthName(root.shown.m) + " " + root.shown.y
                font.pixelSize: 16; font.weight: Font.Bold
            }
            Row {
                anchors.right: parent.right; spacing: 6
                RoundButton { icon: Icons.left; onClicked: root.shift(-1) }
                RoundButton { icon: Icons.calendar; accent: root.monthOffset === 0; onClicked: root.shift(-root.monthOffset || 0) }
                RoundButton { icon: Icons.right; onClicked: root.shift(1) }
            }
        }

        // Kalendergitter
        Column {
            width: parent.width; spacing: 4
            Row {
                Repeater {
                    model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    Txt {
                        required property string modelData
                        width: col.width / 7; horizontalAlignment: Text.AlignHCenter
                        text: modelData; font.pixelSize: 11; font.weight: Font.Bold; color: Theme.textDim
                    }
                }
            }
            Grid {
                id: grid
                columns: 7
                opacity: 1
                transform: Translate { id: gridTr }
                Repeater {
                    model: root.cells
                    delegate: Item {
                        id: cell
                        required property var modelData
                        width: col.width / 7; height: 38
                        Rectangle {
                            anchors.centerIn: parent
                            width: 34; height: 34; radius: 17
                            color: cell.modelData.today ? Theme.accent : cellMa.containsMouse ? Theme.surfaceHi : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                        }
                        Txt {
                            anchors.centerIn: parent
                            text: cell.modelData.day
                            font.weight: cell.modelData.today ? Font.Bold : Font.Normal
                            color: cell.modelData.today ? Theme.onAccent
                                 : !cell.modelData.inMonth ? Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.4)
                                 : cell.modelData.weekend ? Theme.accent2 : Theme.text
                        }
                        MouseArea { id: cellMa; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
            ParallelAnimation {
                id: slide
                NumberAnimation { target: gridTr; property: "x"; from: 40 * root.slideDir; to: 0; duration: Theme.dur(380); easing.type: Easing.OutCubic }
                NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: Theme.dur(300) }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.outline }

        // Timer
        Item {
            width: parent.width; height: 40
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 10
                Glyph { text: Icons.timer; size: 20; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hub.timerRunning ? Hub.fmtTimer(Hub.timerLeft) : "Timer"
                    font.pixelSize: Hub.timerRunning ? 20 : 14; font.weight: Font.Bold
                }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Repeater {
                    model: Hub.timerRunning ? [] : [5, 15, 25, 50]
                    BarButton {
                        required property int modelData
                        label: modelData + "m"
                        color: Theme.surface
                        onClicked: Hub.startTimer(modelData)
                    }
                }
                BarButton {
                    visible: Hub.timerRunning
                    icon: Icons.close; label: "Stopp"
                    active: true
                    onClicked: Hub.stopTimer()
                }
            }
        }
        Meter {
            visible: Hub.timerRunning
            width: parent.width
            value: Hub.timerTotal > 0 ? 1 - Hub.timerLeft / Hub.timerTotal : 0
        }
    }
}
