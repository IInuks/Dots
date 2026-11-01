pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source and per-app streams through Quickshell's native PipeWire module.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool available: Pipewire.ready && sink !== null

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    // app playback streams: Quickshell reports them as isStream && isSink (Stream/Output/Audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink)

    readonly property string icon: muted || volume <= 0.001 ? "volume_off"
                                   : volume < 0.34 ? "volume_mute"
                                   : volume < 0.67 ? "volume_down" : "volume_up"

    // keep audio properties of the defaults and all sinks/sources bound
    PwObjectTracker { objects: [root.sink, root.source].concat(root.sinks, root.sources, root.streams) }

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function step(delta) { setVolume(volume + delta); }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function setMicVolume(v) { if (source?.audio) source.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleMicMute() { if (source?.audio) source.audio.muted = !source.audio.muted; }
    function setDefaultSink(n) { Pipewire.preferredDefaultAudioSink = n; }
    function setDefaultSource(n) { Pipewire.preferredDefaultAudioSource = n; }

    function nodeName(n) {
        return n?.nickname || n?.description || n?.name || "Unknown";
    }
    function streamName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.description || n?.name || "Stream";
    }
}
