import QtQuick
import "../../"
import "../../components"
import "../../services"

// Now playing: big round cover orbited by a dotted ring, title/artist,
// seek slider, transport controls, player switcher. Empty state when
// nothing is playing.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    Keys.onSpacePressed: Player.toggle()
    Keys.onLeftPressed: Player.prev()
    Keys.onRightPressed: Player.next()

    Column {
        id: col
        width: parent.width
        spacing: Theme.s4

        // ---- empty state
        Column {
            visible: !Player.present
            width: parent.width
            spacing: Theme.s3
            Item { width: 1; height: Theme.s2 }
            Orb {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72; height: 72
                color: Theme.media
                ring: true
                glowing: true
            }
            KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "title"; text: "Stille im All" }
            KLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "muted"
                text: "Kein Player gefunden (MPRIS braucht einen DBus-Session-Bus)"
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ---- cover
        Item {
            visible: Player.present
            anchors.horizontalCenter: parent.horizontalCenter
            width: 190; height: 190
            Glow {
                anchors.centerIn: parent
                width: 300; height: 300
                color: Theme.media
                strength: Player.playing ? 0.7 : 0.25
                Behavior on strength { NumberAnimation { duration: Theme.tSlow * 2 } }
            }
            CoverArt {
                anchors.centerIn: parent
                width: 160; height: 160
                source: Player.art
                orbit: true
                orbitGap: 12
                spinning: Player.playing
                scale: Player.playing ? 1 : 0.94
                Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop } }
            }
        }

        Column {
            visible: Player.present
            width: parent.width
            spacing: 2
            KLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; role: "title"; text: Player.title }
            KLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; role: "muted"; text: Player.artist + (Player.album ? "  ·  " + Player.album : "") }
        }

        // ---- seek
        Column {
            visible: Player.present && Player.length > 0
            width: parent.width
            spacing: 2
            Slider {
                width: parent.width
                value: Player.length > 0 ? Player.position / Player.length : 0
                color: Theme.media
                color2: Theme.magenta
                trackHeight: 8
                height: 22
                onMoved: v => Player.seek(v)
            }
            Item {
                width: parent.width
                height: 14
                KLabel { role: "caps"; text: Player.fmt(Player.position) }
                KLabel { anchors.right: parent.right; role: "caps"; text: Player.fmt(Player.length) }
            }
        }

        // ---- transport
        Row {
            visible: Player.present
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.s4
            IconBadge { anchors.verticalCenter: parent.verticalCenter; width: 42; height: 42; glyph: Glyphs.prev; onClicked: Player.prev() }
            IconBadge {
                width: 60; height: 60
                glyph: Player.playing ? Glyphs.pause : Glyphs.play
                active: true
                color: Theme.media
                onClicked: Player.toggle()
            }
            IconBadge { anchors.verticalCenter: parent.verticalCenter; width: 42; height: 42; glyph: Glyphs.next; onClicked: Player.next() }
        }

        // ---- players
        Flow {
            visible: Player.players.length > 1
            width: parent.width
            spacing: Theme.s2
            Repeater {
                model: Player.players
                Chip {
                    required property var modelData
                    text: modelData.identity || "Player"
                    selected: modelData === Player.active
                    tint: Theme.media
                    onClicked: if (!modelData.isPlaying && modelData.canPlay) modelData.play()
                }
            }
        }
    }
}
