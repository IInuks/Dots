pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Picks "the" media player: the one playing, else the first one.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var active: {
        const ps = root.players;
        return ps.find(p => p.isPlaying) || ps[0] || null;
    }
    readonly property bool present: active !== null
    readonly property bool playing: present && active.isPlaying
    readonly property string title: present ? (active.trackTitle || "Unknown title") : ""
    readonly property string artist: present ? (active.trackArtist || active.identity || "") : ""
    readonly property string album: present ? (active.trackAlbum || "") : ""
    readonly property string art: present ? (active.trackArtUrl || "") : ""
    readonly property real length: present && active.lengthSupported ? active.length : 0
    property real position: 0

    function toggle() { if (present && active.canTogglePlaying) active.togglePlaying(); }
    function next() { if (present && active.canGoNext) active.next(); }
    function prev() { if (present && active.canGoPrevious) active.previous(); }
    function seek(frac) {
        if (present && active.canSeek && length > 0)
            active.position = frac * length;
    }

    // Mpris position is not notified continuously; poll only while playing.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.playing
        onTriggered: root.position = root.active ? root.active.position : 0
    }
    onActiveChanged: position = active ? active.position : 0

    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec));
        const m = Math.floor(sec / 60), s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
