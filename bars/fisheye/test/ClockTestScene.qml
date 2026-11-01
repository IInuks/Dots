import QtQuick
import Quickshell
import ".."
import "../widgets/segment"
import "../widgets/common"
import "../bar/modules"

// Etappe 3 review scene: ClockModule in isolation plus every defined
// FourteenSegment character, so a bad letter shape is caught here instead
// of in the real bar. Temporary -- see the `testMode` switch in shell.qml.
FloatingWindow {
    id: win

    title: "fisheye — clock module test"
    implicitWidth: 700
    implicitHeight: 300
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
        spacing: 24

        Column {
            spacing: 4
            Text {
                text: "CLOCK MODULE (live)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            ClockModule {}
        }

        Column {
            spacing: 4
            width: parent.width
            Text {
                text: "FOURTEEN-SEGMENT ALPHABET (defined subset)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            Row {
                spacing: 4
                Repeater {
                    model: "0123456789".split("")
                    FourteenSegment {
                        required property string modelData
                        char: modelData
                        digitHeight: 30
                    }
                }
            }
            Row {
                spacing: 4
                Repeater {
                    model: "ABDEFGIJKLM".split("")
                    FourteenSegment {
                        required property string modelData
                        char: modelData
                        digitHeight: 30
                    }
                }
            }
            Row {
                spacing: 4
                Repeater {
                    model: "NOPRSTUVZ".split("")
                    FourteenSegment {
                        required property string modelData
                        char: modelData
                        digitHeight: 30
                    }
                }
            }
        }
    }
}
