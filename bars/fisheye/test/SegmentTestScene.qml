import QtQuick
import Quickshell
import ".."
import "../widgets/segment"
import "../widgets/common"

// Etappe 2 review scene: every segment widget in isolation, nothing wired
// to real data yet. Temporary -- see the `testMode` switch in shell.qml.
FloatingWindow {
    id: win

    title: "fisheye — segment widget test"
    implicitWidth: 620
    implicitHeight: 400
    visible: true
    color: "transparent"

    LcdSurface {
        anchors.fill: parent
    }
    BevelPanel {
        anchors.fill: parent
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Row {
            spacing: 6
            Repeater {
                model: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
                SevenSegment {
                    char: modelData
                    digitHeight: 44
                }
            }
        }

        Row {
            spacing: 30

            Column {
                spacing: 4
                Text {
                    text: "GHOST"
                    color: Theme.surfaceInk
                    opacity: 0.55
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                SevenSegment {
                    char: " "
                    digitHeight: 44
                }
            }
            Column {
                spacing: 4
                Text {
                    text: "LIT"
                    color: Theme.surfaceInk
                    opacity: 0.55
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                SevenSegment {
                    char: "8"
                    digitHeight: 44
                }
            }
            Column {
                spacing: 4
                Text {
                    text: "ROLLING (live)"
                    color: Theme.surfaceInk
                    opacity: 0.55
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                Row {
                    spacing: 8
                    RollingDigits {
                        id: rollMinutesTens
                        digitHeight: 44
                        value: "0"
                    }
                    RollingDigits {
                        id: rollMinutes
                        digitHeight: 44
                        value: "0"
                    }
                    Text {
                        text: ":"
                        color: Theme.segmentOn
                        font.pixelSize: 36
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    RollingDigits {
                        id: rollSecondsTens
                        digitHeight: 44
                        value: "0"
                    }
                    RollingDigits {
                        id: rollSeconds
                        digitHeight: 44
                        value: "0"
                    }
                }
            }
        }

        Column {
            spacing: 10
            width: parent.width

            Text {
                text: "SEGMENT BARS"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            SegmentBar {
                width: 320
                height: 12
                value: 0.3
            }
            SegmentBar {
                width: 320
                height: 12
                value: 0.7
            }
            SegmentBar {
                width: 320
                height: 12
                value: 1.0
            }
            SegmentBar {
                width: 320
                height: 12
                value: 0.15
                critical: true
            }
        }
    }

    // Drives the rolling-digit demo so the roll+flicker animation is
    // actually visible, not just present in the code.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let s = (parseInt(rollSeconds.value) + 1) % 10;
            rollSeconds.value = String(s);
            if (s !== 0)
                return;
            let st = (parseInt(rollSecondsTens.value) + 1) % 6;
            rollSecondsTens.value = String(st);
            if (st !== 0)
                return;
            let m = (parseInt(rollMinutes.value) + 1) % 10;
            rollMinutes.value = String(m);
            if (m !== 0)
                return;
            let mt = (parseInt(rollMinutesTens.value) + 1) % 6;
            rollMinutesTens.value = String(mt);
        }
    }
}
