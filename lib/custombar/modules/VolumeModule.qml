import QtQuick
import ".."

// Wheel to change volume by settings.step percent, click to mute/unmute.
Item {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    readonly property int step: settings.step || 5

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Volume.muted ? "✕" : "♪"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: Volume.muted ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5) : root.foreground
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Volume.volume * 100) + "%"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Volume.toggleMute()
        onWheel: wheel => {
            const dir = wheel.angleDelta.y > 0 ? 1 : -1;
            Volume.setVolume(Volume.volume + dir * root.step / 100);
        }
    }
}
