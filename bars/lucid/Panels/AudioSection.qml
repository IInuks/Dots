import QtQuick
import Quickshell.Services.Pipewire
import "../"
import "../Bar"

// Speaker + mic, both via Quickshell's native Pipewire service -- same
// Pipewire.defaultAudioSink/.defaultAudioSource + PwObjectTracker approach
// already proven in bars/fisheye/bar/modules/VolumeModule.qml and
// bars/floating/right/AudioPopup.qml on this system, restyled to this bar's
// Material 3 sliders instead of a SegmentBar/LCD look.
Column {
    id: root
    spacing: 10

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(root.sink && root.sink.audio)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sourceReady: !!(root.source && root.source.audio)

    PwObjectTracker {
        objects: [root.sink, root.source].filter(o => !!o)
    }

    Row {
        width: parent.width
        spacing: 8

        Icon {
            id: speakerIcon
            glyph: root.sinkReady && root.sink.audio.muted ? "volume_off" : "volume_up"
            fallback: root.sinkReady && root.sink.audio.muted ? "✕" : "♫"
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.sinkReady
                onClicked: root.sink.audio.muted = !root.sink.audio.muted
            }
        }
        Slider {
            width: parent.width - speakerIcon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.sinkReady
            value: root.sinkReady ? root.sink.audio.volume : 0
            onMoved: v => { if (root.sinkReady) root.sink.audio.volume = v; }
        }
    }

    Row {
        width: parent.width
        spacing: 8
        visible: root.sourceReady

        Icon {
            id: micIcon
            glyph: root.sourceReady && root.source.audio.muted ? "mic_off" : "mic"
            fallback: root.sourceReady && root.source.audio.muted ? "✕" : "●"
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.sourceReady
                onClicked: root.source.audio.muted = !root.source.audio.muted
            }
        }
        Slider {
            width: parent.width - micIcon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.sourceReady
            value: root.sourceReady ? root.source.audio.volume : 0
            onMoved: v => { if (root.sourceReady) root.source.audio.volume = v; }
        }
    }
}
