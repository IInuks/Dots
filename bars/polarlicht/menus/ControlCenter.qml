pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.widgets

MenuCard {
    id: root
    name: "control"
    width: 420
    height: col.implicitHeight + 40

    property bool showSinks: false
    onOpenChanged: if (!open) showSinks = false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top; anchors.margins: 20
        spacing: 14

        // Kopf: Palette aus dem Wallpaper
        Item {
            width: parent.width; height: 44
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: "Polarlicht"; font.pixelSize: 18; font.weight: Font.Bold }
                Txt { text: "läuft seit " + Hub.fmtUptime(Hub.uptime); font.pixelSize: 11; color: Theme.textDim }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                RoundButton { icon: Icons.image; onClicked: Hub.open("walls") }
                RoundButton { icon: Icons.pulse; onClicked: Hub.open("system") }
                RoundButton { icon: Icons.power; onClicked: Hub.open("power") }
            }
        }

        // Lautstärke
        Row {
            width: parent.width; spacing: 8
            Fader {
                width: parent.width - 52
                value: Hub.volume
                dimmed: Hub.muted
                icon: Hub.volIcon(Hub.volume, Hub.muted)
                onMoved: v => Hub.setVolume(v)
                onIconClicked: if (Hub.sink?.audio) Hub.sink.audio.muted = !Hub.sink.audio.muted
            }
            RoundButton {
                size: 44; icon: Icons.speaker; accent: root.showSinks
                onClicked: root.showSinks = !root.showSinks
            }
        }

        // Ausgabegeräte (ausklappbar)
        Item {
            width: parent.width
            height: root.showSinks ? sinkCol.implicitHeight : 0
            clip: true
            Behavior on height { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutCubic } }
            Column {
                id: sinkCol
                width: parent.width; spacing: 4
                Repeater {
                    model: root.sinks
                    delegate: Rectangle {
                        id: sinkItem
                        required property PwNode modelData
                        readonly property bool cur: Hub.sink === modelData
                        width: sinkCol.width; height: 38; radius: 12
                        color: cur ? Theme.accentSoft : sinkMa.containsMouse ? Theme.surface : "transparent"
                        Row {
                            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                            Glyph { text: sinkItem.cur ? Icons.check : Icons.speaker; size: 15; color: sinkItem.cur ? Theme.accent : Theme.textDim }
                            Txt { width: sinkCol.width - 60; text: sinkItem.modelData.description || sinkItem.modelData.nickname || sinkItem.modelData.name }
                        }
                        MouseArea { id: sinkMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = sinkItem.modelData }
                    }
                }
            }
        }

        Fader {
            width: parent.width
            visible: Hub.source !== null
            value: Hub.micVolume
            dimmed: Hub.micMuted
            icon: Hub.micMuted ? Icons.micOff : Icons.mic
            onMoved: v => Hub.setMic(v)
            onIconClicked: if (Hub.source?.audio) Hub.source.audio.muted = !Hub.source.audio.muted
        }

        // Schnellschalter
        Grid {
            width: parent.width
            columns: 2; columnSpacing: 8; rowSpacing: 8
            readonly property real cw: (width - 8) / 2
            Tile {
                width: parent.cw; icon: Icons.coffee; label: "Wach bleiben"
                sub: on ? "Kein Idle" : "Aus"; on: Theme.cfg.caffeine
                onClicked: Theme.cfg.caffeine = !Theme.cfg.caffeine
            }
            Tile {
                width: parent.cw; icon: Icons.clock; label: "Sekunden"
                sub: on ? "In der Uhr" : "Aus"; on: Theme.cfg.clockSeconds
                onClicked: Theme.cfg.clockSeconds = !Theme.cfg.clockSeconds
            }
            Tile {
                width: parent.cw; icon: Icons.overview; label: "Übersicht"
                sub: "mango"; onClicked: { Hub.close(); Hub.dispatch("toggleoverview") }
            }
            Tile {
                id: gapsTile
                property bool gaps: true
                width: parent.cw; icon: Icons.grid; label: "Lücken"
                sub: gaps ? "An" : "Aus"; on: gaps
                onClicked: { gaps = !gaps; Hub.dispatch("togglegaps") }
            }
        }

        SectionTitle { text: "Erscheinung" }

        Segmented {
            width: parent.width
            current: Theme.cfg.mode
            options: [
                { value: "auto", label: "Auto", icon: Icons.auto },
                { value: "dark", label: "Dunkel", icon: Icons.moon },
                { value: "light", label: "Hell", icon: Icons.sun }
            ]
            onPicked: v => Theme.cfg.mode = v
        }
        Segmented {
            width: parent.width
            current: Theme.cfg.scheme
            options: [
                { value: "tonal", label: "Tonal" },
                { value: "vibrant", label: "Lebhaft" },
                { value: "mono", label: "Mono" }
            ]
            onPicked: v => Theme.cfg.scheme = v
        }
        Segmented {
            width: parent.width
            current: Theme.cfg.anim
            options: [
                { value: 1.0, label: "Weich", icon: Icons.star },
                { value: 0.55, label: "Flott", icon: Icons.bolt },
                { value: 0, label: "Aus" }
            ]
            onPicked: v => Theme.cfg.anim = v
        }

        // Akzent aus dem Wallpaper wählen
        Column {
            width: parent.width; spacing: 8
            Row {
                width: parent.width
                SectionTitle { text: "Akzent aus dem Wallpaper"; width: parent.width - autoBtn.width }
                Txt {
                    id: autoBtn
                    text: Theme.cfg.seedPick < 0 ? "automatisch" : "zurücksetzen"
                    font.pixelSize: 11
                    color: Theme.accent
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.cfg.seedPick = -1 }
                }
            }
            Row {
                spacing: 8
                Repeater {
                    model: Theme.swatches
                    delegate: Rectangle {
                        id: sw
                        required property color modelData
                        required property int index
                        readonly property bool sel: Theme.cfg.seedPick === index
                        width: 36; height: 36; radius: sel ? 12 : 18
                        color: modelData
                        border.width: sel ? 3 : 1
                        border.color: sel ? Theme.text : Theme.outline
                        scale: swMa.containsMouse ? 1.15 : 1
                        Behavior on radius { NumberAnimation { duration: Theme.dur(250) } }
                        Behavior on scale { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutBack } }
                        MouseArea { id: swMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Theme.cfg.seedPick = sw.index }
                    }
                }
            }
        }
    }
}
