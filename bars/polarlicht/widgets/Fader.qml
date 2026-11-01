import QtQuick
import qs

// Dicker Schieberegler mit Icon im Inneren (Material-You-Stil)
Item {
    id: root
    property real value: 0
    property string icon: ""
    property bool dimmed: false
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 44
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(parent.height, root.value * parent.width)
            radius: height / 2
            color: root.dimmed ? Theme.surfaceHi : Theme.accent
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
        }
        Rectangle {  // Griff
            x: fill.width - width - 8
            anchors.verticalCenter: parent.verticalCenter
            width: 4; height: ma.pressed ? 26 : 18; radius: 2
            color: root.dimmed ? Theme.textDim : Theme.onAccent
            opacity: 0.7
            Behavior on height { NumberAnimation { duration: Theme.dur(150) } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.leftMargin: 44
        cursorShape: Qt.PointingHandCursor
        function upd(mx) { root.moved(Math.max(0, Math.min(1, (mx + 44) / root.width))) }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
    MouseArea {
        width: 44; height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.iconClicked()
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
    Glyph {
        x: 14; anchors.verticalCenter: parent.verticalCenter
        text: root.icon; size: 18
        color: root.dimmed ? Theme.textDim : Theme.onAccent
    }
    Txt {
        anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.value * 100) + "%"
        color: root.value > 0.86 && !root.dimmed ? Theme.onAccent : Theme.textDim
        font.weight: Font.DemiBold
    }
}
