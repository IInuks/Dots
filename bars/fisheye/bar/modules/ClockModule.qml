import QtQuick
import Quickshell
import "../.."
import "../../widgets/segment"

// The bar's centerpiece: HH:MM from SystemClock (no Timer/polling), a colon
// that fades rather than snaps each second, small subscript seconds, and
// the date spelled out in 14-segment characters beside it. Clicking opens
// the analog watch-face popup (Bar.qml owns the PopupShell/ClockMenu, this
// only emits `clicked`, same split VolumeModule uses for its mixer).
Item {
    id: root

    signal clicked

    readonly property real digitHeight: Theme.density === "compact" ? 16 : 20
    readonly property real secDigitHeight: digitHeight * 0.55
    readonly property real dateDigitHeight: digitHeight * 0.65

    implicitWidth: timeRow.implicitWidth + dateGap + dateRow.implicitWidth
    implicitHeight: Math.max(digitHeight, dateDigitHeight)

    readonly property int dateGap: 10

    readonly property var _weekdays: ["SO", "MO", "DI", "MI", "DO", "FR", "SA"]
    readonly property var _months: ["JAN", "FEB", "MRZ", "APR", "MAI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ"]

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property int _displayHours: Config.clockFormat === "12h" ? (clock.hours % 12 === 0 ? 12 : clock.hours % 12) : clock.hours
    readonly property string _hh: String(_displayHours).padStart(2, "0")
    readonly property string _mm: String(clock.minutes).padStart(2, "0")
    readonly property string _ss: String(clock.seconds).padStart(2, "0")
    readonly property string _dateStr: _weekdays[clock.date.getDay()] + " " + String(clock.date.getDate()).padStart(2, "0") + " " + _months[clock.date.getMonth()]

    Row {
        id: timeRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        RollingDigits {
            digitHeight: root.digitHeight
            value: root._hh[0]
        }
        RollingDigits {
            digitHeight: root.digitHeight
            value: root._hh[1]
        }

        Item {
            width: root.digitHeight * 0.22
            height: root.digitHeight
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: Math.max(2, root.digitHeight * 0.09)
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.32 - height / 2
                color: Theme.segmentOn
                opacity: clock.seconds % 2 === 0 ? 1 : 0.15
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durBase
                        easing.type: Theme.easeInOut
                    }
                }
            }
            Rectangle {
                width: Math.max(2, root.digitHeight * 0.09)
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.68 - height / 2
                color: Theme.segmentOn
                opacity: clock.seconds % 2 === 0 ? 1 : 0.15
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durBase
                        easing.type: Theme.easeInOut
                    }
                }
            }
        }

        RollingDigits {
            digitHeight: root.digitHeight
            value: root._mm[0]
        }
        RollingDigits {
            digitHeight: root.digitHeight
            value: root._mm[1]
        }

        Item {
            visible: Config.showSeconds
            width: visible ? secRow.implicitWidth + 4 : 0
            height: root.digitHeight
            anchors.bottom: parent.bottom

            Row {
                id: secRow
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.bottom: parent.bottom
                spacing: 1

                RollingDigits {
                    digitHeight: root.secDigitHeight
                    value: root._ss[0]
                }
                RollingDigits {
                    digitHeight: root.secDigitHeight
                    value: root._ss[1]
                }
            }
        }
    }

    Row {
        id: dateRow
        anchors.left: timeRow.right
        anchors.leftMargin: root.dateGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.dateDigitHeight * 0.12

        Repeater {
            model: root._dateStr.split("")
            FourteenSegment {
                required property string modelData
                char: modelData
                digitHeight: root.dateDigitHeight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
