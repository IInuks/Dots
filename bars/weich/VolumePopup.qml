import QtQuick
import Quickshell.Services.Pipewire

PopupCard {
    id: popup
    popupId: "volume"
    edge: "right"
    popupWidth: 240

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: sink ? [sink] : [] }

    Column {
        width: parent.width
        spacing: 4
        Text {
            text: popup.sink ? (popup.sink.description || popup.sink.nickname || popup.sink.name) : "Kein Ausgabegerät"
            elide: Text.ElideRight
            width: parent.width
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.muted
        }
        Row {
            width: parent.width
            spacing: 10
            Rectangle {
                width: 26
                height: 26
                radius: 13
                anchors.verticalCenter: parent.verticalCenter
                color: muteMouse.containsMouse ? Qt.alpha(Theme.foreground, 0.10) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: (popup.sink && popup.sink.audio.muted) ? "🔇" : "🔊"
                    font.pixelSize: Theme.fontSizeNormal
                }
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: popup.sink !== null
                    onClicked: popup.sink.audio.muted = !popup.sink.audio.muted
                }
            }
            SoftSlider {
                width: parent.width - 26 - 40 - 20
                anchors.verticalCenter: parent.verticalCenter
                value: popup.sink ? popup.sink.audio.volume : 0
                onMoved: v => { if (popup.sink) popup.sink.audio.volume = v; }
            }
            Text {
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: popup.sink ? Math.round(popup.sink.audio.volume * 100) + "%" : "--"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.foreground
            }
        }
    }
}
