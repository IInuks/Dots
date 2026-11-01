import QtQuick
import Quickshell.Services.Pipewire
import ".."

// Tab 1 (Audio) des rechten Blobs (Auftrag Abschnitt 6). API-Nutzung
// (Pipewire.defaultAudioSink, Pipewire.nodes, PwObjectTracker,
// node.audio.volume/.muted) uebernommen aus dem bereits produktiv
// laufenden bars/fisheye/menus/SoundMixerMenu.qml -- dort verifiziert,
// hier nur die Optik an Theme.qml angepasst statt der Segment-Widgets.
Item {
    id: root

    readonly property var masterSink: Pipewire.defaultAudioSink
    readonly property bool masterReady: !!(root.masterSink && root.masterSink.audio)

    // Wiedergabe-Streams (Ton geht *zu* einer Sink) -- schliesst Aufnahme-
    // Streams und die Sinks selbst aus, gleicher Filter wie SoundMixerMenu.
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

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Row {
            width: parent.width
            spacing: 6

            Text {
                text: root.masterReady && root.masterSink.audio.muted ? "🔇" : "🔊"
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: {
                        if (root.masterReady)
                            root.masterSink.audio.muted = !root.masterSink.audio.muted;
                    }
                }
            }

            Item {
                id: masterSlider
                width: parent.width - 24 - 34
                height: 16
                anchors.verticalCenter: parent.verticalCenter

                readonly property real value: root.masterReady ? root.masterSink.audio.volume : 0

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.outline
                }
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, masterSlider.value))
                    height: 4
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => masterSlider._setFromX(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            masterSlider._setFromX(mouse.x);
                    }
                }

                function _setFromX(px) {
                    if (!root.masterReady)
                        return;
                    root.masterSink.audio.volume = Math.max(0, Math.min(1, px / width));
                }
            }

            Text {
                text: Math.round(masterSlider.value * 100) + "%"
                color: Theme.surfaceInk
                font.pixelSize: 11
                width: 30
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
        }

        Repeater {
            model: root.streamNodes

            Row {
                id: appRow
                required property var modelData

                width: parent.width
                spacing: 6

                Text {
                    text: root.appLabel(appRow.modelData)
                    color: Theme.surfaceInk
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: 70
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: appSlider
                    width: appRow.width - 70 - 6
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property real value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 3
                        radius: 1.5
                        color: Theme.outline
                    }
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, appSlider.value))
                        height: 3
                        radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => appSlider._setFromX(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                appSlider._setFromX(mouse.x);
                        }
                    }

                    function _setFromX(px) {
                        if (!appRow.modelData.audio)
                            return;
                        appRow.modelData.audio.volume = Math.max(0, Math.min(1, px / width));
                    }
                }
            }
        }

        Text {
            visible: root.streamNodes.length === 0
            text: "Keine Programme"
            color: Theme.surfaceInk
            opacity: 0.5
            font.pixelSize: 11
        }
    }
}
