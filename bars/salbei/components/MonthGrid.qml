import QtQuick
import "../"

// Month view: "‹  October 2026  ›", Sun–Sat headers, optional ISO week column.
// Today = filled accent square. Used by the desktop widget, popup and CC page.
Column {
    id: root

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    property bool weekNumbers: true
    property real cell: 30
    property int fontSize: Theme.fontSmall
    property bool showHeader: true
    // overridable colors (desktop widget: follow the wallpaper brightness)
    property color textColor: Theme.text
    property color dimColor: Theme.textDim
    property color faintColor: Theme.textFaint
    property color accentColor: Theme.accent
    property color accentInkColor: Theme.accentInk
    property color hoverColor: Theme.hover

    spacing: 6

    function shift(n) {
        let m = month + n, y = year;
        while (m < 0) { m += 12; y--; }
        while (m > 11) { m -= 12; y++; }
        _go(y, m, n);
    }
    function reset() {
        const y = today.getFullYear(), m = today.getMonth();
        if (y === year && m === month) return;
        _go(y, m, (y * 12 + m) > (year * 12 + month) ? 1 : -1);
    }

    // month change: the grid slides out against the direction and the new month slides in
    property int _dir: 1
    property int _toYear
    property int _toMonth
    function _go(y, m, dir) {
        _dir = dir > 0 ? 1 : -1;
        _toYear = y;
        _toMonth = m;
        flip.restart();
    }
    SequentialAnimation {
        id: flip
        ParallelAnimation {
            NumberAnimation { target: days; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InQuad }
            NumberAnimation { target: daysShift; property: "x"; to: -24 * root._dir; duration: 120; easing.type: Easing.InQuad }
            NumberAnimation { target: title; property: "opacity"; to: 0; duration: 120 }
        }
        ScriptAction { script: { root.year = root._toYear; root.month = root._toMonth; } }
        ParallelAnimation {
            NumberAnimation { target: days; property: "opacity"; to: 1; duration: 260 }
            NumberAnimation { target: daysShift; property: "x"; from: 24 * root._dir; to: 0; duration: 380; easing.type: Theme.easingSpring; easing.overshoot: 1.2 }
            NumberAnimation { target: title; property: "opacity"; to: 1; duration: 260 }
            NumberAnimation { target: titleShift; property: "y"; from: 8 * root._dir; to: 0; duration: 380; easing.type: Theme.easingSpring }
        }
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    // 6 rows × 7 days starting on the Sunday on/before the 1st
    readonly property var days: {
        const first = new Date(year, month, 1);
        const start = new Date(year, month, 1 - first.getDay());
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                isToday: d.toDateString() === today.toDateString(),
                date: d
            });
        }
        return out;
    }

    // header: ‹  Month Year  ›
    Item {
        visible: root.showHeader
        width: parent.width
        height: 26

        Txt {
            id: title
            anchors.centerIn: parent
            transform: Translate { id: titleShift }
            text: Qt.locale("en_US").standaloneMonthName(root.month) + " " + root.year
            font.pixelSize: root.fontSize + 2
            font.weight: Font.DemiBold
            color: root.textColor
        }
        Repeater {
            model: [-1, 1]
            Rectangle {
                required property int modelData
                anchors.verticalCenter: parent.verticalCenter
                x: modelData < 0 ? 0 : parent.width - width
                width: 24
                height: 24
                radius: Theme.radiusIconButton
                color: arrowMouse.containsMouse ? root.hoverColor : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                scale: arrowMouse.pressed ? 0.85 : 1
                Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
                Icon {
                    anchors.centerIn: parent
                    name: modelData < 0 ? "chevron_left" : "chevron_right"
                    color: root.dimColor
                    size: Theme.iconItem
                }
                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shift(modelData)
                }
            }
        }
        MouseArea {
            anchors.centerIn: parent
            width: 140
            height: parent.height
            onClicked: root.reset()
        }
    }

    Grid {
        id: days
        columns: root.weekNumbers ? 8 : 7
        anchors.horizontalCenter: parent.horizontalCenter
        transform: Translate { id: daysShift }

        Repeater {
            model: (root.weekNumbers ? [""] : []).concat(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"])
            Txt {
                required property string modelData
                width: root.cell
                height: root.cell * 0.8
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: root.dimColor
                font.pixelSize: root.fontSize - 1
            }
        }

        Repeater {
            model: root.weekNumbers ? 48 : 42
            Item {
                required property int index
                readonly property bool weekCell: root.weekNumbers && index % 8 === 0
                readonly property int dayIndex: root.weekNumbers ? index - Math.floor(index / 8) - 1 : index
                readonly property var info: weekCell ? null : root.days[dayIndex]
                width: root.cell
                height: root.cell

                // hover wash on day cells
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - 4
                    height: root.cell - 4
                    radius: Theme.radiusDay
                    color: root.hoverColor
                    opacity: dayMouse.containsMouse && !parent.weekCell && !(parent.info?.isToday ?? false) ? 1 : 0
                    scale: opacity > 0 ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
                }
                MouseArea { id: dayMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                // today: accent square with a slow breathing halo
                Rectangle {
                    id: halo
                    anchors.centerIn: parent
                    width: root.cell - 4
                    height: root.cell - 4
                    radius: Theme.radiusDay
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.accentColor
                    visible: parent.info?.isToday ?? false
                    SequentialAnimation on scale {
                        running: halo.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 1.35; duration: 1800; easing.type: Easing.OutCubic }
                        PauseAnimation { duration: 1400 }
                    }
                    SequentialAnimation on opacity {
                        running: halo.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.7; to: 0; duration: 1800; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 1400 }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - 4
                    height: root.cell - 4
                    radius: Theme.radiusDay
                    color: root.accentColor
                    visible: parent.info?.isToday ?? false
                }
                Txt {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: root.fontSize
                    font.weight: parent.info?.isToday ? Font.Bold : Font.Normal
                    text: parent.weekCell ? root.isoWeek(root.days[parent.index / 8 * 7 + 1].date)
                                          : parent.info.day
                    color: parent.weekCell ? root.faintColor
                         : parent.info.isToday ? root.accentInkColor
                         : parent.info.inMonth ? root.textColor : root.faintColor
                }
            }
        }
    }
}
