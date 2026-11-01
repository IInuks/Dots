import QtQuick
import Quickshell

// Klang: großer Pegel-Tropfen, Lautstärke, Mikro, Ausgabegerät.
Drip {
    id: root
    popupId: "control"
    cardWidth: 360

    Column {
        width: parent.width
        spacing: 14

        Row {
            spacing: 16
            Droplet {
                width: 50; height: 68
                level: Audio.muted ? 0 : Audio.volume
                fill: Theme.accent; empty: Theme.surface3
                rim: Theme.alpha(Theme.accent, 0.4)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Label {
                    text: Audio.muted ? "stumm" : Math.round(Audio.volume * 100) + " %"
                    rounded: true; bold: true; size: 30
                    color: Audio.muted ? Theme.textDim : Theme.text
                }
                Label {
                    width: 240
                    text: Audio.sink ? (Audio.sink.description || Audio.sink.nickname || Audio.sink.name) : "kein Ausgang"
                    size: 12; color: Theme.textDim
                }
            }
        }

        Row {
            width: parent.width
            spacing: 12
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Audio.icon(); size: 18; width: 22
                color: Audio.muted ? Theme.textFaint : Theme.text
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
            }
            Pegel {
                width: parent.width - 34
                anchors.verticalCenter: parent.verticalCenter
                value: Audio.volume; off: Audio.muted
                onMoved: v => Audio.setVolume(v)
            }
        }
        Row {
            width: parent.width
            spacing: 12
            visible: Audio.micReady
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Audio.micMuted ? "micOff" : "mic"; size: 18; width: 22
                color: Audio.micMuted ? Theme.textFaint : Theme.text
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMic() }
            }
            Pegel {
                width: parent.width - 34
                anchors.verticalCenter: parent.verticalCenter
                value: Audio.micVolume; off: Audio.micMuted; tint: Theme.accent2
                onMoved: v => Audio.setMic(v)
            }
        }

        Heading { text: "Ausgang"; visible: Audio.sinks.length > 1 }
        Column {
            width: parent.width
            spacing: 4
            visible: Audio.sinks.length > 1
            Repeater {
                model: Audio.sinks
                delegate: Rectangle {
                    id: out
                    required property var modelData
                    readonly property bool cur: Audio.sink === modelData
                    width: parent.width; height: 38; radius: 19
                    color: cur ? Theme.alpha(Theme.accent, 0.16) : (oma.containsMouse ? Theme.alpha(Theme.text, 0.05) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }
                    Droplet {
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        width: 11; height: 15; shine: false
                        fill: out.cur ? Theme.accent : Theme.textFaint
                    }
                    Label {
                        x: 36; width: parent.width - 50
                        anchors.verticalCenter: parent.verticalCenter
                        text: out.modelData.description || out.modelData.nickname || out.modelData.name
                        size: 12.5; bold: out.cur
                    }
                    MouseArea { id: oma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Audio.setSink(out.modelData) }
                }
            }
        }
        Label {
            visible: !Audio.ready
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Kein PipeWire. Startet die Shell vor PipeWire, bleibt das so (siehe README)."
            size: 12; color: Theme.textDim
        }
    }
}
