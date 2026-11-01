import QtQuick

// Schieberegler: dicke Spur, Füllung im Akzent, Griff wächst beim Ziehen.
Item {
    id: s
    property real value: 0          // 0..1
    property color tint: Theme.accent
    signal moved(real v)
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 10; radius: 5
        color: Theme.surface3
        Rectangle {
            width: Math.max(10, s.value * parent.width); height: parent.height; radius: 5
            color: s.tint
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        x: s.value * (s.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: ma.pressed || ma.containsMouse ? 22 : 16; height: width; radius: width / 2
        color: Theme.text
        border.width: 3; border.color: s.tint
        Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
        Behavior on x { enabled: !ma.pressed; NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function upd(m) { s.moved(Math.max(0, Math.min(1, m.x / width))); }
        onPressed: m => upd(m)
        onPositionChanged: m => { if (pressed) upd(m); }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
