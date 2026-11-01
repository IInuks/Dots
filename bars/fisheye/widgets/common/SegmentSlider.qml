import QtQuick
import "../.."
import "../segment"

// Drag-to-set control built on SegmentBar -- same discrete-block look as
// every other level readout in the bar, just interactive. Used by the
// sound mixer menu (master + per-app volume).
Item {
    id: root

    property real value: 0 // 0..1
    property int segmentCount: 10
    signal moved(real value)

    implicitHeight: 12

    SegmentBar {
        anchors.fill: parent
        segmentCount: root.segmentCount
        value: root.value
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, mouse.x / width)));
        }
    }
}
