import QtQuick
import Quickshell.Services.Pipewire

// Icon + percent in the bar; scroll adjusts volume directly, click opens
// the Command Center's System tab for the full mixer.
Item {
    id: root
    signal clicked()
    implicitWidth: row.implicitWidth
    implicitHeight: 20

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Row {
        id: row
        spacing: 5
        anchors.centerIn: parent

        Icon {
            name: (root.muted || root.volume === 0) ? "volumeMute" : "volumeHigh"
            size: 14
            tint: root.muted ? Theme.textDim : Theme.text
            anchors.verticalCenter: parent.verticalCenter
            Behavior on tint { ColorAnimation { duration: Theme.animMed } }
        }
        Text {
            text: Math.round(root.volume * 100) + "%"
            color: Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: mouse => { if (mouse.button === Qt.MiddleButton && root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted; }
        onWheel: wheel => {
            if (!root.sink || !root.sink.audio) return;
            const dir = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + dir));
        }
        scale: containsMouse ? 1.1 : 1
        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
    }
}
