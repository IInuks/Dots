import QtQuick
import Quickshell

// Center of the bar: the clock. Hovering opens a liquid menu containing the
// live-search app launcher.
LiquidMenu {
    id: clockMenu

    menuWidth: 260
    menuContentHeight: 260
    pinned: LauncherState.pinned
    // In vertical mode the open-gesture moves onto the workspace dots
    // (Bar.qml wires their hover into externalHover below) instead of the
    // clock trigger itself.
    triggerHoverEnabled: !Settings.vertical

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    trigger: Component {
        Item {
            implicitWidth: Settings.vertical ? Settings.barThickness : (label.implicitWidth + 24)
            implicitHeight: Settings.vertical ? (stack.implicitHeight + 10) : Theme.barHeight

            // Horizontal bar: time (+ optional day/date) on one line.
            Text {
                id: label
                visible: !Settings.vertical
                anchors.centerIn: parent
                text: Settings.showClockDate
                    ? Qt.formatDateTime(clock.date, "hh:mm  ddd, dd MMM")
                    : Qt.formatDateTime(clock.date, "hh:mm")
                color: Theme.foreground
                font.pixelSize: 13
            }

            // Vertical bar: not enough width for one long line, so time and
            // day/date stack as short lines instead (bar is thickened for
            // this in Settings.barThickness).
            Column {
                id: stack
                visible: Settings.vertical
                anchors.centerIn: parent
                spacing: 1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    color: Theme.foreground
                    font.pixelSize: 13
                }
                Text {
                    visible: Settings.showClockDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "ddd")
                    color: Theme.mutedText
                    font.pixelSize: 10
                }
                Text {
                    visible: Settings.showClockDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dd.MM")
                    color: Theme.mutedText
                    font.pixelSize: 10
                }
            }
        }
    }

    content: Component {
        Launcher {
            anchors.fill: parent
            onCloseRequested: LauncherState.pinned = false
        }
    }
}
