import QtQuick
import QtQuick.Layouts
import "../../"
import "../../components"
import "../../services"

// Remote server (Tailscale + SSH): CPU, memory, disks, load, temperature, traffic.
ColumnLayout {
    spacing: Theme.tileGap

    Component.onCompleted: Server.watchers++
    Component.onDestruction: Server.watchers--

    readonly property bool ok: Server.status === "ok"
    readonly property var rootDisk: Server.disks.find(d => d.mount === "/") ?? Server.disks[0] ?? { mount: "/", used: 0, total: 0 }

    function gib(b) { return (b / 1073741824).toFixed(1) + " GiB"; }
    function size(b) { return b >= 1099511627776 ? (b / 1099511627776).toFixed(2) + " TiB" : gib(b); }
    function rate(b) {
        return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s"
             : b >= 1024 ? Math.round(b / 1024) + " kB/s" : Math.round(b) + " B/s";
    }

    // header: host, status, ssh
    Tile {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Icon {
                name: "dns"
                size: 22
                color: ok ? Theme.accent : Server.status === "connecting" ? Theme.textDim : Theme.danger
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt {
                    text: ok ? Server.hostname : Server.target
                    font.weight: Font.DemiBold
                }
                Txt {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Theme.textDim
                    font.pixelSize: Theme.fontSmall
                    text: ({
                        ok: "Linux " + Server.kernel + " · up " + SystemStats.formatUptime(Server.uptime),
                        connecting: "Connecting…",
                        idle: "Connecting…",
                        auth: "Login needed: open the terminal once (password) or set up a key.",
                        check: "Tailscale SSH wants a confirmation: open the terminal and click the link.",
                        offline: "Unreachable. Is Tailscale running? " + Server.error
                    })[Server.status]
                }
            }
            IconButton {
                visible: Server.status === "auth"
                icon: "key"
                implicitWidth: 34
                implicitHeight: 34
                onClicked: { Server.setupKey(); Ui.controlCenterOpen = false; }
            }
            IconButton {
                visible: !ok
                icon: "refresh"
                implicitWidth: 34
                implicitHeight: 34
                onClicked: Server.poll()
            }
            IconButton {
                icon: "terminal"
                implicitWidth: 34
                implicitHeight: 34
                onClicked: { Server.openShell(); Ui.controlCenterOpen = false; }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Theme.tileGap
        columnSpacing: Theme.tileGap
        opacity: ok ? 1 : 0.45
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        Meter { order: 1; icon: "speed"; label: "CPU"; value: Server.cpu; detail: Server.cores + " cores" }
        Meter { order: 1; icon: "memory"; label: "Memory"; value: Server.memUsed / Math.max(1, Server.memTotal); detail: gib(Server.memUsed) + " / " + gib(Server.memTotal) }
        Meter { order: 1; icon: "hard_drive"; label: "Disk " + rootDisk.mount; value: rootDisk.used / Math.max(1, rootDisk.total); detail: size(rootDisk.used) + " / " + size(rootDisk.total) }
    }

    Tile {
        order: 2
        Layout.fillWidth: true
        Layout.preferredHeight: 84
        opacity: ok ? 1 : 0.45
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            Repeater {
                model: [
                    { l: "Load", v: Server.load[0].toFixed(2), hot: Server.load[0] > Server.cores },
                    { l: "Temp", v: isNaN(Server.temp) ? "–" : Math.round(Server.temp) + "°C", hot: Server.temp >= 85 },
                    { l: "Swap", v: Server.swapTotal > 0 ? gib(Server.swapUsed) : "–", hot: false },
                    { l: "↓ / ↑", v: rate(Server.rxRate) + " / " + rate(Server.txRate), hot: false, small: true }
                ]
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: modelData.small ? 2 : 1
                    spacing: 2
                    Txt { text: modelData.l; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                    Txt {
                        text: modelData.v
                        font.pixelSize: modelData.small ? 15 : 20
                        font.weight: Font.Bold
                        color: modelData.hot ? Theme.danger : Theme.accent
                    }
                }
            }
        }
    }

    // other mounts; the model is just the count, so tiles survive each poll
    // instead of being rebuilt (and replaying their entrance) every few seconds
    readonly property var otherDisks: Server.disks.filter(d => d !== rootDisk).slice(0, 3)
    Repeater {
        model: otherDisks.length
        Tile {
            required property int index
            readonly property var modelData: otherDisks[index] ?? { mount: "", used: 0, total: 0 }
            order: 3 + index
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10
                Icon { name: "hard_drive"; size: 16; color: Theme.textDim }
                Txt { text: modelData.mount; Layout.preferredWidth: 120; elide: Text.ElideMiddle }
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Theme.track
                    Rectangle {
                        readonly property real v: modelData.used / Math.max(1, modelData.total)
                        width: parent.width * Math.min(1, v)
                        height: parent.height
                        radius: 3
                        color: v > 0.85 ? Theme.danger : Theme.accent
                    }
                }
                Txt { text: size(modelData.used) + " / " + size(modelData.total); color: Theme.textDim; font.pixelSize: Theme.fontTiny }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
