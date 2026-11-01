import QtQuick
import Quickshell.Services.Pipewire
import ".."

// Small flyout for the volume gauge: mute toggle + slider, so the gauge
// itself no longer needs to mute on click.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.volumeWidth
    panelHeight: Metrics.volumeHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: sink !== null && sink.audio !== null
    readonly property bool muted: !hasAudio || sink.audio.muted

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Row {
            width: parent.width
            spacing: 10

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                name: "volume"
                width: 16; height: 16
                tint: root.muted ? Chroma.textFaint : Chroma.accent2
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16 - 34 - 20
                text: "Lautstärke"
                color: Chroma.text
                font.family: Metrics.fontFamily
                font.pixelSize: 12
            }
            Rectangle {
                width: 34; height: 18; radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: root.muted ? Chroma.accent : Chroma.panelRaised
                Behavior on color { ColorAnimation { duration: Chroma.tMed } }

                Rectangle {
                    width: 12; height: 12; radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.muted ? parent.width - width - 3 : 3
                    color: Chroma.text
                    Behavior on x { SpringAnimation { spring: 3.5; damping: 0.45 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.hasAudio) root.sink.audio.muted = !root.sink.audio.muted
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10

            Slider {
                width: parent.width - 40
                anchors.verticalCenter: parent.verticalCenter
                value: root.hasAudio ? root.sink.audio.volume : 0
                onMoved: v => { if (root.hasAudio) root.sink.audio.volume = v; }
            }
            Text {
                width: 30
                anchors.verticalCenter: parent.verticalCenter
                text: root.hasAudio ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
                color: Chroma.text
                font.family: Metrics.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
