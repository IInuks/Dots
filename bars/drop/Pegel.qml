import QtQuick

// Schieber als Wasserpegel: die Füllung schwillt beim Anfassen an, Mausrad
// und Klick/Ziehen setzen den Wert. `moved(v)` meldet den neuen Wert.
Item {
    id: s
    property real value: 0
    property color tint: Theme.accent
    property bool off: false
    signal moved(real v)

    implicitHeight: 26
    readonly property bool hot: ma.containsMouse || ma.pressed

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: s.hot ? 16 : 10
        radius: height / 2
        color: Theme.surface3
        Behavior on height { SpringAnimation { spring: 5; damping: 0.2; epsilon: 0.05 } }

        Rectangle {
            height: parent.height
            radius: height / 2
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, s.value)))
            color: s.off ? Theme.textFaint : s.tint
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
            // Glanz auf dem Pegel
            Rectangle {
                x: parent.radius * 0.6; y: 2
                width: Math.max(0, parent.width - parent.radius * 1.2); height: Math.max(1, parent.height * 0.22)
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.22)
            }
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(x) { s.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x); }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
    }
}
