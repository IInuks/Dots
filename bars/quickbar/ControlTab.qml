import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Column {
    id: root
    spacing: 16

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0

    readonly property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) || list[0] || null;
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Row {
        width: parent.width
        spacing: 10

        Item {
            width: 20; height: 20
            anchors.verticalCenter: parent.verticalCenter
            Icon {
                anchors.centerIn: parent
                name: (root.muted || root.volume === 0) ? "volumeMute" : "volumeHigh"
                size: 16
                tint: Theme.text
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        Slider {
            width: parent.width - 30
            anchors.verticalCenter: parent.verticalCenter
            value: root.volume
            onMoved: v => { if (root.sink && root.sink.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v; } }
        }
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: Theme.radiusMed
        color: Theme.surfaceAlt
        visible: NotificationState.items.length > 0

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: NotificationState.unreadCount + " neue Nachricht" + (NotificationState.unreadCount === 1 ? "" : "en")
                color: Theme.text
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: NotificationState.items.length > 0 ? NotificationState.items[0].summary : ""
                color: Theme.textDim
                font.pixelSize: 12
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: BigMenuState.selectTab(2)
        }
    }

    Rectangle {
        width: parent.width
        height: 120
        radius: Theme.radiusMed
        color: Theme.surfaceAlt
        visible: root.player !== null

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.player ? (root.player.trackTitle || "Unbekannter Titel") : ""
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.player ? [root.player.trackArtist, root.player.identity].filter(s => s).join(" · ") : ""
                color: Theme.textDim
                font.pixelSize: 11
            }

            Slider {
                width: parent.width
                value: (root.player && root.player.length > 0) ? root.player.position / root.player.length : 0
                fillColor: Theme.accent2
                onMoved: v => { if (root.player && root.player.positionSupported) root.player.position = v * root.player.length; }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                Icon {
                    name: "prevTrack"; size: 16; tint: Theme.text
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.player && root.player.previous() }
                }
                Icon {
                    name: root.player && root.player.isPlaying ? "pause" : "play"; size: 18; tint: Theme.accent
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.player && root.player.togglePlaying() }
                }
                Icon {
                    name: "nextTrack"; size: 16; tint: Theme.text
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.player && root.player.next() }
                }
            }
        }
    }
}
