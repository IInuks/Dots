import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../widgets/common"
import "../widgets/segment"

// Master volume + per-application mixer, opened from VolumeModule's left
// click (middle-click on the bar icon still does the quick mute toggle,
// see VolumeModule.qml). Sliders are SegmentSlider -- the same discrete-
// block look as every other level readout, not a smooth progress fill.
Item {
    id: root

    readonly property var masterSink: Pipewire.defaultAudioSink
    readonly property bool masterReady: !!(root.masterSink && root.masterSink.audio)

    // App playback streams (things sending audio *to* a sink) -- excludes
    // recording/input streams and the sinks themselves. Same filter as
    // bars/shellbar/SettingsMenu.qml's proven soundTabComponent.
    readonly property var streamNodes: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        return all.filter(n => n.isStream && n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream);
    }

    function appLabel(node) {
        const p = node.properties || {};
        return p["application.name"] || node.description || node.name || "?";
    }

    PwObjectTracker {
        objects: root.masterSink ? [root.masterSink] : []
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                spacing: 6

                Text {
                    text: "MASTER"
                    color: Theme.surfaceInk
                    opacity: 0.7
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    width: 44
                    anchors.verticalCenter: parent.verticalCenter
                }
                SegmentSlider {
                    id: masterSlider
                    width: parent.width - 44 - 34 - 12
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.masterReady ? root.masterSink.audio.volume : 0
                    onMoved: v => {
                        if (root.masterReady)
                            root.masterSink.audio.volume = v;
                    }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Repeater {
                        model: String(Math.round((root.masterReady ? root.masterSink.audio.volume : 0) * 100)).padStart(3, " ").split("")
                        SevenSegment {
                            required property string modelData
                            char: modelData
                            digitHeight: 12
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.bevelDark
            }

            Repeater {
                model: root.streamNodes

                Row {
                    id: appRow
                    required property var modelData
                    width: col.width
                    spacing: 6

                    Text {
                        text: root.appLabel(appRow.modelData)
                        color: Theme.surfaceInk
                        opacity: 0.85
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: 70
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    SegmentSlider {
                        width: appRow.width - 70 - 6
                        anchors.verticalCenter: parent.verticalCenter
                        segmentCount: 8
                        value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                        onMoved: v => {
                            if (appRow.modelData.audio)
                                appRow.modelData.audio.volume = v;
                        }
                    }
                }
            }

            Text {
                visible: root.streamNodes.length === 0
                text: "KEINE PROGRAMME"
                color: Theme.surfaceInk
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 1
            }
        }
    }
}
