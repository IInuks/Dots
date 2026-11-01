import QtQuick
import Quickshell.Services.Pipewire
import "../.."
import "../../widgets/segment"

// Default sink volume as a SegmentBar, plus a small mute cross overlay.
// Scroll adjusts volume directly; left-click opens the sound mixer popup
// (Bar.qml owns the PopupShell/SoundMixerMenu, this only emits `clicked`);
// middle-click toggles mute, same split fullshell's/quickbar's Volume.qml
// already use elsewhere in this user's setup.
Item {
    id: root

    signal clicked

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.audio)
    readonly property bool muted: ready && sink.audio.muted
    readonly property real volume: ready ? sink.audio.volume : 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth: 34
    implicitHeight: 12

    SegmentBar {
        anchors.fill: parent
        segmentCount: 6
        value: root.muted ? 0 : root.volume
    }

    // Mute cross: two thin diagonals, only shown while muted.
    Item {
        anchors.fill: parent
        visible: root.muted
        opacity: 0.9

        Rectangle {
            width: parent.width * 0.9
            height: 2
            anchors.centerIn: parent
            rotation: 28
            color: Theme.critical
        }
        Rectangle {
            width: parent.width * 0.9
            height: 2
            anchors.centerIn: parent
            rotation: -28
            color: Theme.critical
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.ready)
                    root.sink.audio.muted = !root.sink.audio.muted;
            } else {
                root.clicked();
            }
        }
        onWheel: wheel => {
            if (!root.ready)
                return;
            const dir = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + dir));
        }
    }
}
