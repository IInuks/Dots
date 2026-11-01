pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player to show: the playing one, else the first one.
Singleton {
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Nothing Playing"
    readonly property string artist: player ? (player.trackArtist || player.identity || "") : "Idle"
    readonly property string art: player?.trackArtUrl ?? ""
}
