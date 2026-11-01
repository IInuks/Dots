import QtQuick
import "../../"
import "../../components"
import "../../services"

// System: three big rings, CPU/RAM history, per-core bars, uptime/load.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    component BigRing: Column {
        id: br
        property real value
        property string glyph
        property string label
        property string text
        property color hue
        spacing: Theme.s2
        Ring {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 92; height: 92
            thickness: 9
            value: br.value
            color: br.value < 0.7 ? br.hue : br.value < 0.88 ? Theme.warn : Theme.crit
            glowing: true
            Column {
                anchors.centerIn: parent
                KIcon { anchors.horizontalCenter: parent.horizontalCenter; text: br.glyph; size: 14; color: Theme.textMuted }
                KLabel { anchors.horizontalCenter: parent.horizontalCenter; text: br.text; font.pixelSize: Theme.fBig; font.weight: Font.Bold }
            }
        }
        KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "caps"; text: br.label }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.s4

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.s4
            BigRing { value: Stats.cpu; glyph: Glyphs.cpu; label: "Prozessor"; text: Math.round(Stats.cpu * 100) + "%"; hue: Theme.accent }
            BigRing { value: Stats.mem; glyph: Glyphs.memory; label: "Speicher"; text: Math.round(Stats.mem * 100) + "%"; hue: Theme.purple }
            BigRing {
                visible: Stats.temp > 0
                value: Math.max(0, (Stats.temp - 30) / 65)
                glyph: Glyphs.temp
                label: "Temperatur"
                text: Math.round(Stats.temp) + "°"
                hue: Theme.orange
            }
        }

        SectionTitle { width: parent.width; text: "Verlauf · 80 s" }
        Rectangle {
            width: parent.width
            height: 84
            radius: Theme.rMed
            color: Theme.alpha(Theme.surfaceSunken, 0.8)
            Sparkline {
                anchors.fill: parent
                anchors.margins: Theme.s3
                values: Stats.memHistory
                color: Theme.purple
                capacity: Stats.historyLength
            }
            Sparkline {
                anchors.fill: parent
                anchors.margins: Theme.s3
                values: Stats.cpuHistory
                color: Theme.accent
                capacity: Stats.historyLength
            }
        }

        SectionTitle { width: parent.width; text: Stats.cores.length + " Kerne" }
        Row {
            id: cores
            width: parent.width
            height: 46
            spacing: 4
            readonly property real bw: (width - (Stats.cores.length - 1) * spacing) / Math.max(1, Stats.cores.length)
            Repeater {
                model: Stats.cores
                Item {
                    required property real modelData
                    width: cores.bw
                    height: cores.height
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.surfaceSunken
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(width, parent.height * modelData)
                        radius: width / 2
                        color: Theme.levelColor(modelData)
                        Behavior on height { NumberAnimation { duration: Theme.tSlow * 2; easing.type: Theme.easeOut } }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.s2
            Chip { text: "Online " + Stats.uptime; glyph: Glyphs.flash; tint: Theme.green }
            Chip { text: "Last " + Stats.load.map(v => v.toFixed(2)).join(" "); glyph: Glyphs.cpu }
            Chip { text: Stats.memUsedGiB.toFixed(1) + " / " + Stats.memTotalGiB.toFixed(0) + " GiB"; glyph: Glyphs.memory; tint: Theme.purple }
        }
    }
}
