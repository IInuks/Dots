import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."

// Volume click target (spec 4 "Audio-Menü"): output device list, master
// volume + mute, mic device + volume + mute, and a live per-program mixer.
// Master/per-app mixer pattern ported from shellbar/SettingsMenu.qml's
// soundTabComponent (Pipewire.defaultAudioSink, PwObjectTracker,
// streamNodes filtered on PwNodeType.AudioOutStream); device enumeration/
// switching is new (shellbar never listed sink/source devices, only the
// current default) -- verify live once real output/input devices are
// available to switch between.
PopupBase {
    id: popup
    popupWidth: 300
    popupHeight: col.implicitHeight + 20

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(sink && sink.ready && sink.audio)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sourceReady: !!(source && source.ready && source.audio)

    readonly property var allNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var sinkNodes: allNodes.filter(n => n.isSink && !n.isStream)
    readonly property var sourceNodes: allNodes.filter(n => n.isSource && !n.isStream)
    readonly property var streamNodes: allNodes.filter(n => n.isStream && n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)

    function appLabel(node) {
        const p = node.properties || {};
        return p["application.name"] || node.description || node.name || "?";
    }
    function isHeadphoneNode(node) {
        if (!node) return false;
        const p = node.properties || {};
        const form = p["device.form_factor"] || "";
        return form === "headphone" || form === "headset";
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    ColumnLayout {
        id: col
        width: popup.popupWidth - 20
        spacing: 10

        Text { text: "Ausgabegerät"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: popup.sinkNodes
                delegate: Rectangle {
                    id: sinkRow
                    required property var modelData
                    readonly property bool isDefault: popup.sink && sinkRow.modelData.id === popup.sink.id
                    Layout.fillWidth: true
                    radius: 6
                    color: sinkRow.isDefault ? Qt.alpha(Theme.textMuted, 0.14) : "transparent"
                    implicitHeight: 24

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6
                        Icon {
                            name: popup.isHeadphoneNode(sinkRow.modelData) ? "headphones" : "volumeHigh"
                            size: 12
                            tint: sinkRow.isDefault ? Theme.text : Theme.textMuted
                        }
                        Text {
                            text: popup.appLabel(sinkRow.modelData)
                            color: sinkRow.isDefault ? Theme.text : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SliderRow {
                Layout.fillWidth: true
                label: "Master"
                value: popup.sinkReady ? popup.sink.audio.volume : 0
                onMoved: v => { if (popup.sinkReady) popup.sink.audio.volume = v; }
            }
            Icon {
                name: popup.sinkReady && popup.sink.audio.muted ? "volumeMute" : "volumeHigh"
                size: 15
                tint: popup.sinkReady && popup.sink.audio.muted ? Theme.urgent : Theme.text
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (popup.sinkReady) popup.sink.audio.muted = !popup.sink.audio.muted; }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        Text { text: "Mikrofon"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: popup.sourceNodes
                delegate: Rectangle {
                    id: sourceRow
                    required property var modelData
                    readonly property bool isDefault: popup.source && sourceRow.modelData.id === popup.source.id
                    Layout.fillWidth: true
                    radius: 6
                    color: sourceRow.isDefault ? Qt.alpha(Theme.textMuted, 0.14) : "transparent"
                    implicitHeight: 22

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: popup.appLabel(sourceRow.modelData)
                        color: sourceRow.isDefault ? Theme.text : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SliderRow {
                Layout.fillWidth: true
                label: ""
                showPercent: true
                value: popup.sourceReady ? popup.source.audio.volume : 0
                onMoved: v => { if (popup.sourceReady) popup.source.audio.volume = v; }
            }
            Icon {
                name: popup.sourceReady && popup.source.audio.muted ? "micOff" : "micOn"
                size: 15
                tint: popup.sourceReady && popup.source.audio.muted ? Theme.urgent : Theme.text
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (popup.sourceReady) popup.source.audio.muted = !popup.source.audio.muted; }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        Text { text: "Programme"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: popup.streamNodes
                delegate: SliderRow {
                    id: appRow
                    required property var modelData
                    Layout.fillWidth: true
                    label: popup.appLabel(appRow.modelData)
                    value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                    onMoved: v => { if (appRow.modelData.audio) appRow.modelData.audio.volume = v; }
                }
            }
            Text {
                visible: popup.streamNodes.length === 0
                text: "Keine aktiven Programme"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.italic: true
            }
        }
    }
}
