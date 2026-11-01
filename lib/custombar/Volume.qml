pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

// Default audio sink volume/mute, shared by every VolumeModule instance.
// Same Pipewire.defaultAudioSink + PwObjectTracker approach as
// bars/quickbar/ControlTab.qml. Lives directly in lib/custombar/, see
// SysStats.qml's comment on why (singleton cross-directory import quirk).
QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0

    function setVolume(v) {
        if (root.sink && root.sink.audio) {
            root.sink.audio.muted = false;
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    function toggleMute() {
        if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
    }

    // QtObject has no default property -- PwObjectTracker must be attached
    // via a named property, not as a bare child (see SysStats.qml's Timer).
    property PwObjectTracker _tracker: PwObjectTracker { objects: root.sink ? [root.sink] : [] }
}
