pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Pipewire-Hülle: Standard-Ausgang/-Eingang, Geräteliste, und jede
// Lautstärke-Änderung (auch von Tasten/wpctl) löst das OSD aus.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: !ready || sink.audio.muted
    readonly property bool micReady: source !== null && source.audio !== null
    readonly property real micVolume: micReady ? source.audio.volume : 0
    readonly property bool micMuted: !micReady || source.audio.muted

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    PwObjectTracker { objects: [root.sink, root.source].filter(x => x !== null) }

    function setVolume(v) { if (ready) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }
    function setMic(v) { if (micReady) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMic() { if (micReady) source.audio.muted = !source.audio.muted; }
    function nudge(d) { setVolume(volume + d); }
    function setSink(n) { Pipewire.preferredDefaultAudioSink = n; }

    function icon() {
        if (muted || volume <= 0.001) return "volOff";
        return volume < 0.34 ? "volLow" : volume < 0.67 ? "volMid" : "volHigh";
    }

    // erst nach dem Start reagieren, sonst blitzt das OSD beim Laden auf
    property bool _armed: false
    Timer { interval: 1500; running: true; onTriggered: root._armed = true }
    onVolumeChanged: if (_armed) Ui.osd("volume")
    onMutedChanged: if (_armed) Ui.osd("volume")
    onMicMutedChanged: if (_armed) Ui.osd("mic")
}
