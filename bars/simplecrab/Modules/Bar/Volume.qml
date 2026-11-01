import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

// Lautstaerke-Icon: Scroll aendert die Lautstaerke direkt, Klick oeffnet
// VolumeMenu.qml mit Regler + Stummschalter (gleiches Popup-Muster wie
// Power.qml/SpiderTrigger.qml).
Item {
    id: root

    required property ShellScreen screen
    property bool menuOpen: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: sink !== null && sink.audio !== null
    readonly property bool muted: !hasAudio || sink.audio.muted
    readonly property real volume: hasAudio ? sink.audio.volume : 0

    // Haelt den Sink-Node "gebunden", solange das Widget existiert -- ohne
    // Tracker liefert Pipewire keine laufenden Updates fuer volume/muted.
    // VolumeMenu.qml bekommt denselben Sink uebergeben und braucht deshalb
    // keinen eigenen Tracker.
    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: {
            if (root.muted || root.volume <= 0)
                return ""; // nf-fa-volume_mute
            if (root.volume < 0.5)
                return ""; // nf-fa-volume_down
            return ""; // nf-fa-volume_up
        }
        font.family: Colors.fontFamily
        font.pointSize: Colors.fontSize
        color: root.menuOpen ? Colors.accent : (root.muted ? Colors.textDim : Colors.text)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
        onWheel: event => {
            if (!root.hasAudio)
                return;
            const delta = event.angleDelta.y > 0 ? Settings.volumeStep : -Settings.volumeStep;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
        }
    }

    LazyLoader {
        active: root.menuOpen

        VolumeMenu {
            screen: root.screen
            sink: root.sink
            onDismissed: root.menuOpen = false
        }
    }
}
