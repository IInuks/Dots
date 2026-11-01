import QtQuick

// Generic 0..1 drag slider, custom-drawn to match the theme (no
// QtQuick.Controls styling to fight with).
Item {
    id: root
    implicitHeight: 16

    property real value: 0 // 0..1, external source of truth
    property color fillColor: Theme.accent
    signal moved(real value)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: 2.5
        color: Theme.surfaceAlt
    }
    Rectangle {
        id: fill
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: 5
        radius: 2.5
        color: root.fillColor
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 100 } }
    }
    Rectangle {
        width: 13; height: 13; radius: 6.5
        color: Theme.text
        anchors.verticalCenter: parent.verticalCenter
        x: fill.width - width / 2
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        onPressed: mouse => root._setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root._setFromX(mouse.x); }
    }

    function _setFromX(px) {
        const v = Math.max(0, Math.min(1, px / root.width));
        root.moved(v);
    }
}
