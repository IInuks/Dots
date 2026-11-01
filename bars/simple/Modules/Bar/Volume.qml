import QtQuick
import Quickshell.Services.Pipewire
import "../.."

// Lautstaerke-Icon: Scroll aendert die Lautstaerke, Klick mutet.
Text {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: sink !== null && sink.audio !== null
    readonly property bool muted: !hasAudio || sink.audio.muted
    readonly property real volume: hasAudio ? sink.audio.volume : 0

    // Haelt den Sink-Node "gebunden", solange das Widget existiert -- ohne
    // Tracker liefert Pipewire keine laufenden Updates fuer volume/muted.
    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    text: {
        if (root.muted || root.volume <= 0)
            return ""; // nf-fa-volume_mute
        if (root.volume < 0.5)
            return ""; // nf-fa-volume_down
        return ""; // nf-fa-volume_up
    }
    font.family: Colors.fontFamily
    font.pointSize: Colors.fontSize
    color: root.muted ? Colors.textDim : Colors.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.hasAudio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
        onWheel: event => {
            if (!root.hasAudio)
                return;
            const delta = event.angleDelta.y > 0 ? Settings.volumeStep : -Settings.volumeStep;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
        }
    }
}
