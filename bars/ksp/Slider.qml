import QtQuick

// Minimal click/drag slider. value is 0..1; onMoved(v) fires on every
// change (click or drag), not just on release.
Item {
    id: root
    height: 6
    property real value: 0
    property color trackColor: Theme.accent
    signal moved(real v)

    function _setFromX(x) {
        const v = Math.max(0, Math.min(1, x / root.width));
        root.moved(v);
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.panelRaised
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width * root.value
        height: 4
        radius: 2
        color: root.trackColor
        Behavior on width { enabled: !dragArea.pressed; NumberAnimation { duration: Theme.tFast } }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        width: 12
        height: 12
        radius: 6
        color: Theme.text
        border.width: 1
        border.color: root.trackColor
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root._setFromX(mouse.x - 6)
        onPositionChanged: mouse => { if (pressed) root._setFromX(mouse.x - 6); }
    }
}
