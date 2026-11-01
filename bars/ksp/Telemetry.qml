import QtQuick

// New flyout: live system telemetry framed as flight data -- uptime as a
// big seven-segment "Mission Elapsed Time" readout (the strongest new
// retro element), CPU/memory as segmented gauges, and a scrolling
// terminal-style data ticker at the bottom for continuous motion while
// the panel is open. Data comes from SysStats.qml (own /proc polling
// singleton, same restart-on-exit pattern MangoIpc.qml uses for `mmsg
// watch`).
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.telemetryWidth
    panelHeight: Metrics.telemetryHeight
    title: "Telemetry"

    function _pad(n, width) {
        let s = Math.max(0, Math.floor(n)).toString();
        while (s.length < width) s = "0" + s;
        return s;
    }

    readonly property real _days: Math.floor(SysStats.uptimeSeconds / 86400)
    readonly property real _hours: Math.floor((SysStats.uptimeSeconds % 86400) / 3600)
    readonly property real _mins: Math.floor((SysStats.uptimeSeconds % 3600) / 60)
    readonly property real _secs: Math.floor(SysStats.uptimeSeconds % 60)
    readonly property string _met: root._pad(root._days, 3) + ":" + root._pad(root._hours, 2) + ":" + root._pad(root._mins, 2) + ":" + root._pad(root._secs, 2)

    Column {
        anchors.fill: parent
        spacing: 16

        Column {
            width: parent.width
            spacing: 6
            Text {
                text: "MISSION ELAPSED TIME"
                color: Theme.textFaint
                font.family: Metrics.fontMono
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }
            SevenSegmentDisplay {
                value: root._met
                digitHeight: 26
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Column {
            width: parent.width
            spacing: 8
            Row {
                width: parent.width
                Text {
                    text: "CPU LOAD"
                    color: Theme.textFaint
                    font.family: Metrics.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    width: parent.width - 50
                }
                Text {
                    text: Math.round(SysStats.cpuPercent * 100) + "%"
                    color: Theme.text
                    font.family: Metrics.fontMono
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            Gauge { width: parent.width; height: 14; segments: 20; value: SysStats.cpuPercent }
        }

        Column {
            width: parent.width
            spacing: 8
            Row {
                width: parent.width
                Text {
                    text: "MEMORY"
                    color: Theme.textFaint
                    font.family: Metrics.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    width: parent.width - 100
                }
                Text {
                    text: SysStats.memUsedGiB.toFixed(1) + " / " + SysStats.memTotalGiB.toFixed(1) + " GiB"
                    color: Theme.text
                    font.family: Metrics.fontMono
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            Gauge { width: parent.width; height: 14; segments: 20; value: SysStats.memPercent }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.accent, 0.2) }

        Item {
            id: tickerBox
            width: parent.width
            height: 18
            clip: true

            readonly property string _line: "HOST " + (SysStats.hostname || "?") + "  ·  KERNEL " + (SysStats.kernel || "?") + "  ·  UPLINK STABLE  ·  ALL SYSTEMS NOMINAL  ·  "

            Text {
                id: tickerText
                text: tickerBox._line
                color: Theme.accent
                font.family: Metrics.fontMono
                font.pixelSize: 11
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
                x: tickerBox.width

                SequentialAnimation on x {
                    id: tickerAnim
                    running: root.shown
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: tickerBox.width
                        to: -tickerText.implicitWidth
                        duration: Math.max(4000, tickerText.implicitWidth * 22)
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}
