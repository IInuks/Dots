import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../../components"
import "../../services"

Flickable {
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { width: 3; contentItem: Rectangle { implicitWidth: 3; radius: 1.5; color: Theme.textFaint } }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: Theme.tileGap

        Txt { visible: !Audio.available; text: "PipeWire not available"; color: Theme.textDim }

        // output
        Tile {
            order: 1
            Layout.fillWidth: true
            Layout.preferredHeight: outCol.implicitHeight + 28
            visible: Audio.available
            ColumnLayout {
                id: outCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    IconButton { icon: Audio.icon; filled: false; onClicked: Audio.toggleMute() }
                    Txt { text: "Output"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Txt { text: Math.round(Audio.volume * 100) + "%"; color: Theme.textDim }
                }
                Slider { Layout.fillWidth: true; value: Audio.volume; onMoved: v => Audio.setVolume(v) }
                Repeater {
                    model: Audio.sinks
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: modelData === Audio.sink ? "check" : "headphones"
                        label: Audio.nodeName(modelData)
                        selected: modelData === Audio.sink
                        onClicked: Audio.setDefaultSink(modelData)
                    }
                }
            }
        }

        // input
        Tile {
            order: 2
            Layout.fillWidth: true
            Layout.preferredHeight: inCol.implicitHeight + 28
            visible: Audio.source !== null
            ColumnLayout {
                id: inCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    IconButton { icon: Audio.micMuted ? "mic_off" : "mic"; filled: false; onClicked: Audio.toggleMicMute() }
                    Txt { text: "Input"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Txt { text: Math.round(Audio.micVolume * 100) + "%"; color: Theme.textDim }
                }
                Slider { Layout.fillWidth: true; value: Audio.micVolume; onMoved: v => Audio.setMicVolume(v) }
                Repeater {
                    model: Audio.sources
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: modelData === Audio.source ? "check" : "mic"
                        label: Audio.nodeName(modelData)
                        selected: modelData === Audio.source
                        onClicked: Audio.setDefaultSource(modelData)
                    }
                }
            }
        }

        // apps
        Tile {
            order: 3
            Layout.fillWidth: true
            Layout.preferredHeight: appCol.implicitHeight + 28
            visible: Audio.streams.length > 0
            ColumnLayout {
                id: appCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6
                Txt { text: "Applications"; font.weight: Font.DemiBold }
                Repeater {
                    model: Audio.streams
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Txt { text: Audio.streamName(modelData); Layout.fillWidth: true; font.pixelSize: Theme.fontSmall }
                            Txt { text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                        }
                        Slider {
                            Layout.fillWidth: true
                            value: modelData.audio?.volume ?? 0
                            onMoved: v => { if (modelData.audio) modelData.audio.volume = v; }
                        }
                    }
                }
            }
        }
    }
}
