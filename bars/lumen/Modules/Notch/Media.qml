import QtQuick
import Quickshell.Services.Mpris
import "../.."

// MPRIS-Widget: Noten-Icon + Titel, ausgeblendet ohne laufenden Player.
Item {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        if (players.length === 0)
            return null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying)
                return players[i];
        }
        return players[0];
    }

    visible: player !== null
    implicitWidth: mediaRow.implicitWidth
    implicitHeight: mediaRow.implicitHeight

    Row {
        id: mediaRow
        spacing: 6

        Text {
            text: "" // nf-fa-music
            font.family: Colors.fontFamily
            font.pointSize: Colors.fontSize
            color: Colors.accentAlt
        }

        Text {
            readonly property string title: root.player !== null ? (root.player.trackTitle || "") : ""

            text: title.length > Settings.trackTitleMaxLength ? title.substring(0, Settings.trackTitleMaxLength - 1) + "…" : title
            font.family: Colors.fontFamily
            font.pointSize: Colors.fontSize
            font.letterSpacing: Colors.letterSpacing
            color: Colors.text
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.player !== null)
                root.player.togglePlaying();
        }
        onWheel: event => {
            if (root.player === null)
                return;
            if (event.angleDelta.y > 0 && root.player.canGoNext)
                root.player.next();
            else if (event.angleDelta.y < 0 && root.player.canGoPrevious)
                root.player.previous();
        }
    }
}
