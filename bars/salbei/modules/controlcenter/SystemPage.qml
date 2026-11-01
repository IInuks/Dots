import QtQuick
import QtQuick.Layouts
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    Component.onCompleted: SystemStats.diskWatchers++
    Component.onDestruction: SystemStats.diskWatchers--

    function gib(b) { return (b / 1073741824).toFixed(1) + " GiB"; }
    function temp(t) { return isNaN(t) ? "–" : Math.round(t) + "°C"; }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Theme.tileGap
        columnSpacing: Theme.tileGap

        Meter { icon: "speed"; label: "CPU"; value: SystemStats.cpu; detail: SystemStats.cpuText }
        Meter { icon: "memory"; label: "Memory"; value: SystemStats.memUsed / Math.max(1, SystemStats.memTotal); detail: gib(SystemStats.memUsed) + " / " + gib(SystemStats.memTotal) }
        Meter { icon: "hard_drive"; label: "Disk /"; value: SystemStats.diskUsed / Math.max(1, SystemStats.diskTotal); detail: gib(SystemStats.diskUsed) + " / " + gib(SystemStats.diskTotal) }
    }

    Tile {
        order: 1
        Layout.fillWidth: true
        Layout.preferredHeight: 84
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            Repeater {
                model: [
                    { l: "CPU", v: SystemStats.cpuTemp },
                    { l: "GPU", v: SystemStats.gpuTemp },
                    { l: "NVMe", v: SystemStats.nvmeTemp }
                ]
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    Txt { text: modelData.l; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                    Txt {
                        text: temp(modelData.v)
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: modelData.v >= 85 ? Theme.danger : Theme.accent
                    }
                }
            }
        }
    }

    Tile {
        order: 2
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt { text: SystemStats.user + "@" + SystemStats.host; font.weight: Font.DemiBold }
                Txt { text: "Linux " + SystemStats.kernel + " · up " + SystemStats.formatUptime(SystemStats.uptime); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
            }
            IconButton {
                icon: "terminal"
                implicitWidth: 34
                implicitHeight: 34
                onClicked: { Ui.terminal(["--hold", "fastfetch"]); Ui.controlCenterOpen = false; }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
