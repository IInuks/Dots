import QtQuick

// Generic 0..1 drag slider, custom-drawn to match the theme.
Item {
    id: root
    implicitHeight: 18

    property real value: 0
    property color fillColor: Theme.accent
    signal moved(real value)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceAlt
    }
    Rectangle {
        id: fill
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: 6
        radius: 3
        color: root.fillColor
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: Theme.animMed } }
    }
    Rectangle {
        width: 15; height: 15; radius: 7.5
        color: Theme.text
        border.width: 1
        border.color: root.fillColor
        anchors.verticalCenter: parent.verticalCenter
        x: fill.width - width / 2
        scale: drag.pressed ? 1.25 : 1
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.35 } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -4
        onPressed: mouse => root._setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root._setFromX(mouse.x); }
    }

    function _setFromX(px) {
        const v = Math.max(0, Math.min(1, px / root.width));
        root.moved(v);
    }
}
