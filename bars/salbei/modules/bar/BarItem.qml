import QtQuick
import "../../"
import "../../components"

// Icon + value pair used across the bar. Values roll, the icon bounces on hover/scroll,
// `alert` makes the icon breathe (charging, hot CPU).
Item {
    id: root

    property string icon
    property string text
    property color color: Theme.text
    property real dim: 1
    property bool alert: false
    signal clicked
    signal wheel(int delta)

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        opacity: root.dim
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

        Icon {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            color: root.color
            // hover lift: separate from Icon's own swap pop (which uses scale/rotation)
            transform: [
                Scale {
                    origin.x: glyph.width / 2; origin.y: glyph.height / 2
                    xScale: hoverLift.value; yScale: hoverLift.value
                },
                Translate { y: -(hoverLift.value - 1) * 8 }
            ]
            SequentialAnimation on opacity {
                running: root.alert
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
            }
        }
        RollingText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.color
            pixelSize: Theme.fontBar
            duration: 260
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }
    }

    QtObject {
        id: hoverLift
        property real value: mouse.containsMouse ? 1.18 : 1
        Behavior on value { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
    }

    SequentialAnimation {
        id: nudge
        NumberAnimation { target: glyph; property: "scale"; to: 1.3; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: glyph; property: "scale"; to: 1; duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { nudge.restart(); root.clicked(); }
        onWheel: e => { nudge.restart(); root.wheel(e.angleDelta.y); }
    }
}
