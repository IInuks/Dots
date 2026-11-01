import QtQuick

// Minimal drag/click slider, value 0..1.
Item {
    id: root
    property real value: 0
    signal moved(real v)

    implicitHeight: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Chroma.panelRaised

        Rectangle {
            width: track.width * root.value
            height: parent.height
            radius: 2
            color: Chroma.accent
        }
    }

    Rectangle {
        width: 14; height: 14; radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: root.value * (root.width - width)
        color: Chroma.text
        border.width: 1
        border.color: Chroma.accent
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        function apply(mx) {
            const v = Math.max(0, Math.min(1, mx / root.width));
            root.value = v;
            root.moved(v);
        }
        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
    }
}
