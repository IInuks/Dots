import QtQuick
import Quickshell.Services.Pipewire

// System overview: chart cards for CPU/RAM/GPU load, a stat-tile grid for
// temps/disk/uptime/network, battery, and a full sound mixer (master +
// live per-app volume, backed by SysMonData / Pipewire directly).
Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property var streamNodes: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        return all.filter(n => n.isStream && n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream);
    }
    function appLabel(node) {
        const p = node.properties || {};
        return p["application.name"] || node.description || node.name || "?";
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property var chartCards: [
        { label: "CPU", value: Math.round(SysMonData.cpuPercent) + "%", history: SysMonData.cpuHistory, color: Theme.accent },
        { label: "RAM", value: Math.round(SysMonData.ramPercent) + "%", history: SysMonData.ramHistory, color: Theme.accent2 },
        { label: SysMonData.gpuIsNvidia ? "GPU" : "GPU", value: Math.round(SysMonData.gpuPercent) + "%", history: SysMonData.gpuHistory, color: Theme.success }
    ]

    readonly property var tiles: [
        { icon: "cpuChip", label: "CPU-Temp.", value: SysMonData.cpuTemp > 0 ? Math.round(SysMonData.cpuTemp) + "°C" : "—", accent: Theme.accent },
        { icon: "cpuChip", label: "GPU-Temp.", value: SysMonData.gpuTemp > 0 ? Math.round(SysMonData.gpuTemp) + "°C" : "—", accent: Theme.success },
        { icon: "disk", label: "Datenträger", value: SysMonData.diskTotalGB > 0 ? Math.round(SysMonData.diskPercent) + "% · " + SysMonData.diskUsedGB.toFixed(0) + "/" + SysMonData.diskTotalGB.toFixed(0) + " GB" : "—", accent: Theme.warn },
        { icon: "clock", label: "Laufzeit", value: SysMonData.uptimeText, accent: Theme.accent2 },
        { icon: "network", label: "Download", value: SysMonData.netRxKBs.toFixed(0) + " KB/s", accent: Theme.accent },
        { icon: "network", label: "Upload", value: SysMonData.netTxKBs.toFixed(0) + " KB/s", accent: Theme.accent2 }
    ]

    Column {
        id: col
        width: root.width
        spacing: 22

        Row {
            width: parent.width
            spacing: 10

            Repeater {
                model: root.chartCards
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index
                    width: (col.width - 2 * 10) / 3
                    height: 92
                    radius: Theme.radiusMed
                    color: Theme.surfaceAlt

                    opacity: 0
                    Component.onCompleted: entrance.start()
                    SequentialAnimation {
                        id: entrance
                        PauseAnimation { duration: card.index * 60 }
                        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Row {
                            width: parent.width
                            Text { text: card.modelData.label; color: Theme.textDim; font.pixelSize: 10; width: parent.width - 34 }
                            Text { text: card.modelData.value; color: card.modelData.color; font.pixelSize: 12; font.bold: true }
                        }

                        HistoryChart {
                            width: parent.width
                            height: 52
                            history: card.modelData.history
                            color: card.modelData.color
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8
            Text { text: "System"; color: Theme.textDim; font.pixelSize: 11 }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.tiles
                    delegate: StatTile {
                        id: tile
                        required property var modelData
                        required property int index
                        width: (col.width - 8) / 2
                        icon: modelData.icon
                        label: modelData.label
                        value: modelData.value
                        accent: modelData.accent

                        opacity: 0
                        Component.onCompleted: entrance.start()
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation { duration: 180 + tile.index * 40 }
                            NumberAnimation { target: tile; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        Battery {
            id: bat
            visible: available
        }
        MeterRow {
            width: parent.width
            visible: bat.available
            label: "Akku"
            valueText: bat.percent + "%" + (bat.charging ? " ⚡" : "")
            fraction: bat.percent / 100
            barColor: bat.percent < 20 ? Theme.danger : Theme.success
        }

        Column {
            width: parent.width
            spacing: 10
            Text { text: "Ton"; color: Theme.textDim; font.pixelSize: 11 }

            Row {
                width: parent.width
                spacing: 12
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: (root.muted || root.volume === 0) ? "volumeMute" : "volumeHigh"
                    size: 16
                    tint: root.muted ? Theme.danger : Theme.text
                    Behavior on tint { ColorAnimation { duration: Theme.animMed } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
                Text { text: "Master"; color: Theme.textDim; font.pixelSize: 11; width: 46; anchors.verticalCenter: parent.verticalCenter }
                Slider {
                    width: parent.width - 46 - 40 - 24
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.volume
                    onMoved: v => { if (root.sink && root.sink.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v; } }
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.volume * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 11
                }
            }

            Text {
                visible: root.streamNodes.length > 0
                text: "Programme"
                color: Theme.textDim
                font.pixelSize: 10
                topPadding: 4
            }

            Repeater {
                model: root.streamNodes
                delegate: Row {
                    id: appRow
                    required property var modelData
                    required property int index
                    width: col.width
                    spacing: 12

                    opacity: 0
                    Component.onCompleted: entrance.start()
                    SequentialAnimation {
                        id: entrance
                        PauseAnimation { duration: appRow.index * 50 }
                        NumberAnimation { target: appRow; property: "opacity"; to: 1; duration: 220 }
                    }

                    Text {
                        width: 100
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.appLabel(appRow.modelData)
                        color: Theme.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Slider {
                        width: parent.width - 100 - 40 - 24
                        anchors.verticalCenter: parent.verticalCenter
                        fillColor: Theme.accent2
                        value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                        onMoved: v => { if (appRow.modelData.audio) appRow.modelData.audio.volume = v; }
                    }
                    Text {
                        width: 34
                        anchors.verticalCenter: parent.verticalCenter
                        text: appRow.modelData.audio ? Math.round(appRow.modelData.audio.volume * 100) + "%" : "—"
                        color: Theme.textDim
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
