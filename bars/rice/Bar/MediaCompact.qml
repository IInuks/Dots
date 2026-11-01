import QtQuick
import Quickshell.Services.Mpris
import "../"

// Compact MPRIS widget: play/pause + elided title, hidden entirely when
// no player exists. Same player-selection rule as bars/lucid/Panels/
// MediaPanel.qml (playing player, else the first, no multi-player
// switcher). Full transport (seek bar, prev/next) lives in a later
// MediaPlayer panel -- Stage 2, see README.
Row {
    id: root
    spacing: 6
    visible: !!root.player

    readonly property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) || list[0] || null;
    }

    Icon {
        glyph: root.player && root.player.isPlaying ? "pause" : "play_arrow"
        fallback: root.player && root.player.isPlaying ? "||" : "▶"
        size: 16
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            enabled: !!root.player && root.player.canTogglePlaying
            onClicked: root.player.togglePlaying()
        }
    }

    Text {
        text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
        color: Theme.text
        font.family: Theme.uiFontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 140)
        anchors.verticalCenter: parent.verticalCenter
    }
}
