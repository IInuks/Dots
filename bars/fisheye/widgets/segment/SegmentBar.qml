import QtQuick
import "../.."

// Discrete block bar for volume/battery/CPU/RAM -- never a smooth
// progress fill. Segments light up left-to-right with a small per-segment
// stagger (Theme.staggerStep) rather than all snapping at once, and a
// `critical` bar pulses slowly instead of sitting at a flat color.
Item {
    id: root

    property real value: 0.5 // 0..1
    property int segmentCount: 10
    property bool critical: false
    property real segmentSpacing: 2

    implicitHeight: 10

    readonly property int litCount: Math.round(Math.max(0, Math.min(1, value)) * segmentCount)

    Row {
        anchors.fill: parent
        spacing: root.segmentSpacing

        Repeater {
            model: root.segmentCount

            Rectangle {
                id: seg

                required property int index
                readonly property bool targetLit: index < root.litCount
                property bool displayLit: targetLit

                width: (root.width - root.segmentSpacing * (root.segmentCount - 1)) / root.segmentCount
                height: parent.height
                radius: Theme.radius * 0.35
                color: (Boot.selfTest || displayLit) ? Theme.segmentOn : Theme.segmentOff

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durBase
                        easing.type: Theme.easeOut
                    }
                }

                onTargetLitChanged: staggerTimer.restart()
                Timer {
                    id: staggerTimer
                    interval: seg.index * Theme.staggerStep
                    onTriggered: seg.displayLit = seg.targetLit
                }
                Component.onCompleted: staggerTimer.restart()

                SequentialAnimation on opacity {
                    running: root.critical && seg.displayLit
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.35
                        duration: Theme.durSlow * 3
                        easing.type: Theme.easeInOut
                    }
                    NumberAnimation {
                        to: 1
                        duration: Theme.durSlow * 3
                        easing.type: Theme.easeInOut
                    }
                    onRunningChanged: if (!running)
                        seg.opacity = 1
                }
            }
        }
    }
}
