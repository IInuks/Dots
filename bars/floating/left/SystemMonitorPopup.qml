import QtQuick
import QtQuick.Layouts
import ".."

// CPU/RAM/GPU with ~60s history graphs, disk/uptime/network stat tiles, and
// top-5 processes by CPU -- opened from the temperature button (spec 4,
// "System-Monitor"). SysMonData.detailActive gates the heavier polling
// (CPU/RAM/GPU/disk/network/ps) to only run while this popup exists;
// cpuTemp itself keeps polling in the background for the bar's own readout.
PopupBase {
    id: popup
    popupWidth: 300
    popupHeight: col.implicitHeight + 20

    Component.onCompleted: SysMonData.detailActive = true
    Component.onDestruction: SysMonData.detailActive = false

    ColumnLayout {
        id: col
        width: popup.popupWidth - 20
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Text { text: "CPU"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                Text {
                    text: Math.round(SysMonData.cpuPercent) + "%  ·  " + Math.round(SysMonData.cpuTemp) + "°C"
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                }
            }
            HistoryChart { Layout.fillWidth: true; history: SysMonData.cpuHistory }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Text { text: "RAM"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true }
                Text {
                    text: SysMonData.ramTotalGB > 0 ? SysMonData.ramUsedGB.toFixed(1) + " / " + SysMonData.ramTotalGB.toFixed(0) + " GB" : "—"
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                }
            }
            HistoryChart { Layout.fillWidth: true; history: SysMonData.ramHistory }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: SysMonData.gpuIsNvidia ? "GPU" : "GPU (AMD)"
                    color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true
                }
                Text {
                    text: Math.round(SysMonData.gpuPercent) + "%" + (SysMonData.gpuTemp > 0 ? "  ·  " + Math.round(SysMonData.gpuTemp) + "°C" : "")
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                }
            }
            HistoryChart { Layout.fillWidth: true; history: SysMonData.gpuHistory }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            StatTile { label: "Storage"; value: SysMonData.diskTotalGB > 0 ? SysMonData.diskUsedGB.toFixed(0) + " / " + SysMonData.diskTotalGB.toFixed(0) + " GB" : "—" }
            StatTile { label: "Uptime"; value: SysMonData.uptimeText }
            StatTile { label: "Netz ↓"; value: SysMonData.networkDownKBs.toFixed(0) + " KB/s" }
            StatTile { label: "Netz ↑"; value: SysMonData.networkUpKBs.toFixed(0) + " KB/s" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text { text: "Top-Prozesse"; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall }

            Repeater {
                model: SysMonData.topProcesses
                delegate: RowLayout {
                    id: procRow
                    required property var modelData
                    Layout.fillWidth: true
                    Text {
                        text: procRow.modelData.name
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: procRow.modelData.cpu.toFixed(1) + "%"
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
    }
}
