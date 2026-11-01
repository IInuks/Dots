import QtQuick

// Rounded fill-track slider for the volume popup.
Item {
    id: root

    property real value: 0 // 0..1
    property bool dragging: track.pressed
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: height / 2
        color: Qt.alpha(Theme.foreground, 0.14)

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.activeFill
        }

        property bool pressed: mouse.pressed

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -8 // fatter hit area than the visual track
            onPressed: mouseEvent => root._setFromX(mouseEvent.x)
            onPositionChanged: mouseEvent => { if (pressed) root._setFromX(mouseEvent.x); }
        }
    }

    function _setFromX(x) {
        const clamped = Math.max(0, Math.min(track.width, x));
        const v = track.width > 0 ? clamped / track.width : 0;
        root.value = v;
        root.moved(v);
    }
}
