import QtQuick
import Quickshell.Services.Mpris
import "../"
import "../Bar"

// Media-Panel: MPRIS-Steuerung (Cover/Titel/Künstler, Zurück/Play-Pause/
// Vor, Fortschrittsbalken) plus ein cava-Visualizer für das tatsächlich
// hörbare Audio -- bewusst getrennt vom MPRIS-Player, denn nicht jede
// Audioquelle (Spiele, Browser ohne MPRIS-Unterstützung) meldet sich dort;
// der Visualizer läuft unabhängig davon, ob überhaupt ein Player existiert.
// Gleiches Player-Auswahlmuster wie bars/fisheye/MediaModule.qml und
// bars/lumen/Media.qml: spielender Player, sonst der erste, keine
// Mehrfach-Player-Umschaltung -- bewusst nicht Teil des Auftrags.
//
// `active` kommt von Bar.qml (an Pill.open gebunden) und schaltet
// ausschließlich CavaService -- Quickshell.Services.Mpris hält players
// ohnehin ständig aktuell (wie Pipewire.defaultAudioSink in
// AudioSection.qml), nur der eigene cava-Subprozess bei 60fps ist teuer
// genug, um ihn an den offenen Zustand des Panels zu binden.
Flickable {
    id: root

    required property bool active

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    onActiveChanged: root.active ? CavaService.acquire() : CavaService.release()

    readonly property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) || list[0] || null;
    }

    // MPRIS only pushes `position` on play/pause/seek/track-change, not
    // once a second while playing -- interpolate locally between those
    // events (reset on every real update) so the seek bar visibly creeps
    // forward instead of jumping every few seconds. Untested against a
    // real player on this machine (none running here, see README) --
    // resets safely to the real value on every genuine position update
    // either way, so a player that *does* push per-second updates just
    // makes the interpolation a no-op.
    property real _posBase: 0
    property real _posBaseTime: Date.now()
    property int _tick: 0
    readonly property real _interpPosition: {
        root._tick;
        if (!root.player)
            return 0;
        if (!root.player.isPlaying)
            return root.player.position;
        return Math.min(root.player.length, root._posBase + (Date.now() - root._posBaseTime) / 1000);
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            root._posBase = root.player.position;
            root._posBaseTime = Date.now();
        }
    }
    onPlayerChanged: {
        root._posBase = root.player ? root.player.position : 0;
        root._posBaseTime = Date.now();
    }

    Timer {
        interval: 500
        repeat: true
        running: !!root.player && root.player.isPlaying
        onTriggered: root._tick++
    }

    function _fmtTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            seconds = 0;
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Column {
        id: layout
        width: root.width
        spacing: 14
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        Text {
            text: "Media"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.uiFontFamily
        }

        Column {
            width: parent.width - 28
            spacing: 10
            visible: !!root.player

            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    id: art
                    width: 56
                    height: 56
                    radius: 12
                    color: Theme.surfaceVariant
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Icon {
                        anchors.centerIn: parent
                        glyph: "music_note"
                        fallback: "♪"
                        visible: !root.player || !root.player.trackArtUrl
                    }
                }

                Column {
                    width: parent.width - art.width - parent.spacing
                    anchors.verticalCenter: art.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.player ? (root.player.trackTitle || root.player.identity || "?") : ""
                        color: Theme.surfaceInk
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.uiFontFamily
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
                        color: Theme.surfaceVariantInk
                        font.pixelSize: 11
                        font.family: Theme.uiFontFamily
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }
            }

            Slider {
                width: parent.width
                enabled: !!root.player && root.player.positionSupported && root.player.lengthSupported && root.player.length > 0
                value: enabled ? root._interpPosition / root.player.length : 0
                onMoved: v => { if (root.player) root.player.position = v * root.player.length; }
            }

            Row {
                width: parent.width

                Text {
                    text: root.player ? root._fmtTime(root._interpPosition) : "0:00"
                    color: Theme.outline
                    font.pixelSize: 10
                    font.family: Theme.uiFontFamily
                }
                Item {
                    width: parent.width - 80
                    height: 1
                }
                Text {
                    text: root.player ? root._fmtTime(root.player.length) : "0:00"
                    color: Theme.outline
                    font.pixelSize: 10
                    font.family: Theme.uiFontFamily
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                Icon {
                    glyph: "skip_previous"
                    fallback: "|<"
                    opacity: root.player && root.player.canGoPrevious ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: !!root.player && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                }
                Icon {
                    glyph: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                    fallback: root.player && root.player.isPlaying ? "||" : ">"
                    font.pixelSize: 26
                    opacity: root.player && root.player.canTogglePlaying ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: !!root.player && root.player.canTogglePlaying
                        onClicked: root.player.togglePlaying()
                    }
                }
                Icon {
                    glyph: "skip_next"
                    fallback: ">|"
                    opacity: root.player && root.player.canGoNext ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: !!root.player && root.player.canGoNext
                        onClicked: root.player.next()
                    }
                }
            }
        }

        Text {
            visible: !root.player
            text: "Kein Player aktiv"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        CavaBars {
            width: parent.width - 28
            height: 40
        }
    }
}
