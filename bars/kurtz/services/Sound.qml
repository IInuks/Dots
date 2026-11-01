pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"

// Default sink/source volume via Pipewire. `bumped` fires on every volume
// or mute change so the OSD can pop up.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name || "") : ""

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    signal bumped

    readonly property string glyph: muted || volume <= 0.001 ? Glyphs.volMute : volume < 0.34 ? Glyphs.volLow : volume < 0.67 ? Glyphs.volMid : Glyphs.volHigh

    function setVolume(v) {
        if (ready) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function nudge(d) {
        setVolume(volume + d);
    }
    function toggleMute() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }
    function setMicVolume(v) {
        if (source && source.audio)
            source.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMic() {
        if (source && source.audio)
            source.audio.muted = !source.audio.muted;
    }
    function setDefault(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Fire `changed` only for real changes after startup.
    property bool _armed: false
    Timer {
        interval: 1500
        running: true
        onTriggered: root._armed = true
    }
    onVolumeChanged: if (_armed) bumped()
    onMutedChanged: if (_armed) bumped()
}
