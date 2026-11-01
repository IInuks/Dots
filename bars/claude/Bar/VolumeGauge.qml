import QtQuick
import Quickshell.Services.Pipewire
import ".."

// Volume gauge: scroll to change, click opens the volume flyout (slider +
// mute toggle) directly above this icon. Doubles as the meter's
// PwObjectTracker host so the sink stays live-bound.
Meter {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: sink !== null && sink.audio !== null
    readonly property bool muted: !hasAudio || sink.audio.muted

    glyphName: "volume"
    ringColor: muted ? Chroma.textFaint : Chroma.accent2
    value: hasAudio ? sink.audio.volume : 0

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    onClicked: {
        const center = root.mapToItem(null, root.width / 2, 0);
        Popups.toggleAt("volume", center.x);
    }
    onWheel: event => {
        if (!root.hasAudio)
            return;
        const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
    }
}
