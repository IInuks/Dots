import QtQuick
import Quickshell
import "../../"
import "../../components"
import "../../services"

// Control center: greeting, quick toggles, sound, now playing, footer.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property string greeting: {
        const h = clock.hours;
        return h < 5 ? "Gute Nacht" : h < 11 ? "Guten Morgen" : h < 17 ? "Guten Tag" : h < 22 ? "Guten Abend" : "Gute Nacht";
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.s4

        // ---- header
        Row {
            spacing: Theme.s3
            SkyOrb {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                hour: clock.hours
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                KLabel { role: "big"; text: root.greeting }
                KLabel { role: "muted"; text: "Online seit " + Stats.uptime + "  ·  " + Net.label }
            }
        }

        // ---- quick toggles
        Grid {
            width: parent.width
            columns: 2
            columnSpacing: Theme.s2
            rowSpacing: Theme.s2
            readonly property real cw: (width - columnSpacing) / 2

            Tile {
                width: parent.cw
                glyph: Net.glyph
                label: "Netzwerk"
                sub: Net.label
                active: Net.online
                onClicked: if (Net.nmAvailable) Net.setWifi(!Net.wifiEnabled)
            }
            Tile {
                width: parent.cw
                glyph: Config.s.dnd ? Glyphs.bellOff : Glyphs.bell
                label: "Nicht stören"
                active: Config.s.dnd
                accent: Theme.purple
                onClicked: Config.toggle("dnd")
            }
            Tile {
                width: parent.cw
                glyph: Glyphs.star4
                label: "Sternenhimmel"
                active: Config.s.stars
                accent: Theme.yellow
                onClicked: Config.toggle("stars")
            }
            Tile {
                width: parent.cw
                glyph: Glyphs.animation
                label: "Animationen"
                active: Config.s.animations
                accent: Theme.green
                onClicked: Config.toggle("animations")
            }
        }

        // ---- sound
        SectionTitle { width: parent.width; text: "Klang"; color: Theme.accent }
        Row {
            width: parent.width
            spacing: Theme.s3
            IconBadge {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                glyph: Sound.glyph
                active: Sound.muted
                color: Theme.crit
                onClicked: Sound.toggleMute()
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34 - 48 - Theme.s3 * 2
                value: Sound.volume
                to: 1
                onMoved: v => Sound.setVolume(v)
            }
            KLabel {
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                text: Math.round(Sound.volume * 100) + "%"
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
            }
        }
        Row {
            width: parent.width
            spacing: Theme.s3
            visible: Sound.source !== null
            IconBadge {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                glyph: Sound.micMuted ? Glyphs.micOff : Glyphs.mic
                active: Sound.micMuted
                color: Theme.crit
                onClicked: Sound.toggleMic()
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34 - 48 - Theme.s3 * 2
                value: Sound.micVolume
                color: Theme.purple
                color2: Theme.magenta
                onMoved: v => Sound.setMicVolume(v)
            }
            KLabel {
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                text: Math.round(Sound.micVolume * 100) + "%"
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
            }
        }
        // output devices (only if there is a choice)
        Flow {
            width: parent.width
            spacing: Theme.s2
            visible: Sound.sinks.length > 1
            Repeater {
                model: Sound.sinks
                Chip {
                    required property var modelData
                    text: modelData.description || modelData.nickname || modelData.name
                    selected: Sound.sink === modelData
                    onClicked: Sound.setDefault(modelData)
                }
            }
        }

        // ---- now playing
        Rectangle {
            visible: Player.present
            width: parent.width
            height: 64
            radius: Theme.rMed
            color: Theme.surface
            CoverArt {
                id: cover
                x: Theme.s3
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40
                source: Player.art
                orbit: true
                spinning: Player.playing
            }
            Column {
                anchors.left: cover.right
                anchors.leftMargin: Theme.s3 + 4
                anchors.right: ctl.left
                anchors.rightMargin: Theme.s2
                anchors.verticalCenter: parent.verticalCenter
                KLabel { width: parent.width; text: Player.title; font.weight: Font.DemiBold }
                KLabel { width: parent.width; role: "muted"; text: Player.artist }
            }
            Row {
                id: ctl
                anchors.right: parent.right
                anchors.rightMargin: Theme.s2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                IconBadge { width: 30; height: 30; glyph: Glyphs.prev; onClicked: Player.prev() }
                IconBadge { width: 36; height: 36; anchors.verticalCenter: parent.verticalCenter; glyph: Player.playing ? Glyphs.pause : Glyphs.play; active: true; color: Theme.media; onClicked: Player.toggle() }
                IconBadge { width: 30; height: 30; glyph: Glyphs.next; onClicked: Player.next() }
            }
        }

        // ---- footer
        Row {
            anchors.right: parent.right
            spacing: Theme.s2
            Chip { text: "Studio"; glyph: Glyphs.palette; onClicked: Popups.open("studio", Popups.screenName, Popups.anchorX) }
            Chip { text: "System"; glyph: Glyphs.cpu; onClicked: Popups.open("system", Popups.screenName, Popups.anchorX) }
            Chip { text: "Energie"; glyph: Glyphs.power; tint: Theme.crit; onClicked: Popups.open("session", Popups.screenName) }
        }
    }
}
