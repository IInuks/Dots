import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../"
import "../../components"
import "../../services"

// Calendar: a "day arc" (the sun travelling from sunrise to sunset, or
// the moon at night) above a month grid. Scroll or arrows change month.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property int monthOffset: 0
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)

    Keys.onLeftPressed: monthOffset -= 1
    Keys.onRightPressed: monthOffset += 1
    Keys.onSpacePressed: monthOffset = 0

    Column {
        id: col
        width: parent.width
        spacing: Theme.s3

        // ---- day arc ------------------------------------------------------
        Item {
            id: arc
            width: parent.width
            height: 118

            // fraction of the day between 06:00 and 20:00 (day), or the
            // night between 20:00 and 06:00 (moon)
            readonly property real minutes: clock.hours * 60 + clock.minutes
            readonly property bool day: minutes >= 360 && minutes < 1200
            readonly property real t: day ? (minutes - 360) / 840 : ((minutes + 1440 - 1200) % 1440) / 600
            readonly property real cx: width / 2
            readonly property real cy: height - 16
            readonly property real r: Math.min(width / 2 - 24, height - 28)
            readonly property real ang: Math.PI * (1 - t)

            // horizon
            Rectangle {
                x: 0
                y: arc.cy
                width: parent.width
                height: 2
                radius: 1
                color: Theme.alpha(Theme.textFaint, 0.5)
            }
            // dotted path of the sun
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.alpha(arc.day ? Theme.yellow : Theme.textMuted, 0.55)
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [0.01, 3.5]
                    PathAngleArc {
                        centerX: arc.cx
                        centerY: arc.cy
                        radiusX: arc.r
                        radiusY: arc.r
                        startAngle: 180
                        sweepAngle: 180
                    }
                }
                // travelled part, solid
                ShapePath {
                    strokeColor: arc.day ? Theme.yellow : "#DCE3F5"
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: arc.cx
                        centerY: arc.cy
                        radiusX: arc.r
                        radiusY: arc.r
                        startAngle: 180
                        sweepAngle: 180 * arc.t
                    }
                }
            }
            SkyOrb {
                width: 30
                height: 30
                hour: arc.day ? 12 : 23
                x: arc.cx + Math.cos(arc.ang) * arc.r - width / 2
                y: arc.cy - Math.sin(arc.ang) * arc.r - height / 2
            }
            KLabel { x: 0; y: arc.cy + 4; role: "caps"; text: arc.day ? "06:00" : "20:00" }
            KLabel { anchors.right: parent.right; y: arc.cy + 4; role: "caps"; text: arc.day ? "20:00" : "06:00" }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: arc.cy - 58
                KLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.fHuge * 0.7
                    font.weight: Font.Bold
                }
                KLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    role: "muted"
                    text: Theme.date(clock.date, "dddd, d. MMMM")
                }
            }
        }

        // ---- month header ---------------------------------------------------
        Item {
            width: parent.width
            height: 34
            IconBadge {
                anchors.left: parent.left
                width: 30; height: 30
                glyph: Glyphs.left
                onClicked: root.monthOffset -= 1
            }
            KLabel {
                anchors.centerIn: parent
                role: "title"
                text: Theme.date(root.shown, "MMMM yyyy")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset = 0
                }
            }
            IconBadge {
                anchors.right: parent.right
                width: 30; height: 30
                glyph: Glyphs.right
                onClicked: root.monthOffset += 1
            }
        }

        // ---- grid -----------------------------------------------------------
        Grid {
            id: grid
            width: parent.width
            columns: 7
            readonly property real cell: width / 7

            Repeater {
                model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                KLabel {
                    required property string modelData
                    required property int index
                    width: grid.cell
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    role: "caps"
                    text: modelData
                    color: index >= 5 ? Theme.accent : Theme.textMuted
                }
            }
            Repeater {
                model: 42
                Item {
                    id: day
                    required property int index
                    // Monday-first offset
                    readonly property int lead: (root.shown.getDay() + 6) % 7
                    readonly property date d: new Date(root.shown.getFullYear(), root.shown.getMonth(), index - lead + 1)
                    readonly property bool inMonth: d.getMonth() === root.shown.getMonth()
                    readonly property bool today: d.toDateString() === clock.date.toDateString()
                    readonly property bool weekend: index % 7 >= 5
                    width: grid.cell
                    height: 34

                    Orb {
                        anchors.centerIn: parent
                        width: 30; height: 30
                        visible: day.today
                        color: Theme.accent
                        glowing: true
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 30
                        radius: 15
                        color: Theme.surfaceHover
                        visible: dm.containsMouse && !day.today && day.inMonth
                    }
                    KLabel {
                        anchors.centerIn: parent
                        text: day.d.getDate()
                        font.weight: day.today ? Font.Bold : Font.Medium
                        color: day.today ? Theme.bgTop : !day.inMonth ? Theme.textFaint : day.weekend ? Theme.textMuted : Theme.text
                        opacity: day.inMonth ? 1 : 0.5
                    }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1
    }
}
