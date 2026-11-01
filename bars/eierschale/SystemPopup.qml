import QtQuick
import QtQuick.Layouts

// System: große Ringe, Verlauf der letzten Minute, ein Balken pro Kern.
PopupCard {
    id: root
    popupId: "system"
    width: 400

    component BigRing: Item {
        id: br
        property real value
        property string label
        property string sub
        property color tint
        width: 110; height: 110
        Ring { anchors.fill: parent; value: br.value; thickness: 9; tint: br.value > 0.85 ? Theme.bad : br.tint }
        Column {
            anchors.centerIn: parent
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(br.value * 100) + "%"; size: 22; bold: true; font.family: Theme.mono }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: br.label; size: 11; color: Theme.textDim }
        }
        Label { anchors.top: parent.bottom; anchors.topMargin: 6; anchors.horizontalCenter: parent.horizontalCenter; text: br.sub; size: 11; color: Theme.textFaint }
    }

    Column {
        width: parent.width
        spacing: 18

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28
            BigRing { value: Stats.cpu; label: "CPU"; tint: Theme.accent; sub: Stats.temp > 0 ? Math.round(Stats.temp) + " °C" : "" }
            BigRing { value: Stats.mem; label: "RAM"; tint: Theme.accent2; sub: Stats.memUsed.toFixed(1) + " / " + Stats.memTotal.toFixed(0) + " GiB" }
        }

        Item { width: 1; height: 4 }

        Rectangle {
            width: parent.width; height: 90; radius: 14
            color: Theme.surface2
            Kurve { anchors.fill: parent; anchors.margins: 8; values: Stats.memHist; tint: Theme.accent2 }
            Kurve { anchors.fill: parent; anchors.margins: 8; values: Stats.cpuHist; tint: Theme.accent }
            Label { x: 12; y: 8; text: "letzte Minute"; size: 10.5; color: Theme.textFaint }
        }

        // Kerne
        Row {
            width: parent.width
            height: 46
            spacing: 3
            Repeater {
                model: Stats.cores
                Item {
                    required property real modelData
                    width: (parent.width - (Stats.cores.length - 1) * 3) / Math.max(1, Stats.cores.length)
                    height: parent.height
                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.surface2 }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; radius: 3
                        height: Math.max(3, parent.modelData * parent.height)
                        color: Theme.mix(Theme.accent, Theme.bad, parent.modelData)
                        Behavior on height { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        GridLayout {
            width: parent.width
            columns: 2
            rowSpacing: 6
            Label { text: "Läuft seit"; size: 12; color: Theme.textDim }
            Label { Layout.alignment: Qt.AlignRight; text: Stats.uptime; size: 12; font.family: Theme.mono }
            Label { text: "Last (1/5/15)"; size: 12; color: Theme.textDim }
            Label { Layout.alignment: Qt.AlignRight; text: Stats.load.map(x => x.toFixed(2)).join("  "); size: 12; font.family: Theme.mono }
            Label { text: "Kerne"; size: 12; color: Theme.textDim }
            Label { Layout.alignment: Qt.AlignRight; text: Stats.cores.length; size: 12; font.family: Theme.mono }
        }
    }
}
