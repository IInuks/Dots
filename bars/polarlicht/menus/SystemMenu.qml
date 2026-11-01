pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.widgets

MenuCard {
    id: root
    name: "system"
    width: 440
    height: col.implicitHeight + 40

    component Graph: Rectangle {
        id: g
        property string icon
        property string title
        property string value
        property var values: []
        property color tint: Theme.accent
        property bool autoScale: true
        height: 110; radius: 18
        color: Theme.surface
        clip: true
        Sparkline { anchors.fill: parent; anchors.topMargin: 40; values: g.values; stroke: g.tint; autoScale: g.autoScale }
        Row {
            x: 14; y: 12; spacing: 8
            Glyph { text: g.icon; size: 16; color: g.tint }
            Txt { text: g.title; color: Theme.textDim; font.pixelSize: 12 }
        }
        Txt { anchors.right: parent.right; anchors.rightMargin: 14; y: 8; text: g.value; font.pixelSize: 20; font.weight: Font.Bold }
    }

    component Stat: Rectangle {
        id: s
        property string icon
        property string title
        property string value
        property real fill: -1
        height: 64; radius: 16
        color: Theme.surface
        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Rectangle {
                width: 36; height: 36; radius: 18; color: Theme.accentSoft
                anchors.verticalCenter: parent.verticalCenter
                Glyph { anchors.centerIn: parent; text: s.icon; size: 17; color: Theme.accent }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 3
                Txt { text: s.title; font.pixelSize: 11; color: Theme.textDim }
                Txt { text: s.value; font.pixelSize: 14; font.weight: Font.DemiBold }
                Meter { visible: s.fill >= 0; width: s.width - 72; height: 4; value: s.fill }
            }
        }
    }

    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top; anchors.margins: 20
        spacing: 12

        Txt { text: "System"; font.pixelSize: 18; font.weight: Font.Bold }

        Graph {
            width: parent.width; icon: Icons.cpu; title: "Prozessor"
            value: Math.round(Hub.cpu * 100) + "%"; values: Hub.cpuHist
        }
        Graph {
            width: parent.width; icon: Icons.memory; title: "Arbeitsspeicher"
            value: (Hub.memUsed / 1048576).toFixed(1) + " / " + (Hub.memTotal / 1048576).toFixed(0) + " GiB"
            values: Hub.memHist; tint: Theme.accent2; autoScale: false
        }

        Grid {
            width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
            readonly property real cw: (width - 8) / 2
            Stat { width: parent.cw; icon: Icons.temp; title: "CPU-Temperatur"; value: Hub.cpuTemp > 0 ? Hub.cpuTemp.toFixed(0) + " °C" : "–"; fill: Hub.cpuTemp / 95 }
            Stat { width: parent.cw; icon: Icons.gpu; title: "GPU-Temperatur"; value: Hub.gpuTemp > 0 ? Hub.gpuTemp.toFixed(0) + " °C" : "–"; fill: Hub.gpuTemp / 95 }
            Stat { width: parent.cw; icon: Icons.disk; title: "Festplatte /"; value: (Hub.diskUsed / 1048576).toFixed(0) + " / " + (Hub.diskTotal / 1048576).toFixed(0) + " GiB"; fill: Hub.diskTotal > 0 ? Hub.diskUsed / Hub.diskTotal : 0 }
            Stat { width: parent.cw; icon: Icons.clock; title: "Laufzeit · Last"; value: Hub.fmtUptime(Hub.uptime) + " · " + Hub.load.split(" ")[0] }
        }

        SectionTitle { text: "Top-Prozesse" }

        Column {
            width: parent.width; spacing: 2
            Repeater {
                model: Hub.procs
                delegate: Item {
                    id: pr
                    required property var modelData
                    required property int index
                    width: col.width; height: 28
                    Txt { width: parent.width - 150; anchors.verticalCenter: parent.verticalCenter; text: pr.modelData.name }
                    Meter {
                        anchors.right: cpuTxt.left; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 70; value: pr.modelData.cpu / 100
                    }
                    Txt {
                        id: cpuTxt
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 56; horizontalAlignment: Text.AlignRight
                        text: pr.modelData.cpu.toFixed(1) + "%"
                        color: Theme.textDim
                    }
                }
            }
        }
    }
}
