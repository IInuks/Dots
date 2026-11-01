import QtQuick
import "../../"

// System-monitor dropdown, opened by clicking anywhere on the left island
// (TopBar.qml's leftIsland MouseArea -- DropdownState.toggle("sysmonitor")).
// Not part of either original prompt: the bar prompt's own cpu/gpu/memory
// widgets are deliberately compact (just "%  °", click on cpu only "closes
// an open dropdown", gpu/memory not clickable at all -- see prompt section
// 4's table). This adds the detail view those compact numbers don't have
// room for, reusing SystemService's existing ~2s poll (extended with
// per-core/GiB/VRAM/load-average detail, see SystemService.qml) rather than
// polling anything separately. Anchored flush-left under the left island,
// per the bar prompt's own dropdown-position line ("linke Seite bündig
// links") -- never actually built before since nothing on the left island
// was clickable yet.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 8

    readonly property int _coreBarMaxHeight: 24

    // MenuRow's value column is a fixed 32px (sized for "48%"-style
    // strings, see MenuRow.qml) -- too narrow for "8.0/16.0G"-style GiB
    // values, so those rows use this instead.
    component WideRow: Item {
        id: wideRow
        property string iconGlyph: ""
        property string label: ""
        property string value: ""
        implicitHeight: 20
        height: 20

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                width: 14
                height: wideRow.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.iconFont
                font.pixelSize: 12
                color: Colors.primary
                text: wideRow.iconGlyph
            }
            Text {
                height: wideRow.height
                verticalAlignment: Text.AlignVCenter
                font.family: Style.textFont
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Colors.backgroundText
                text: wideRow.label
            }
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: wideRow.value
        }
    }

    Text {
        text: "CPU"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    MenuRow {
        width: root.width
        iconGlyph: "\u{F0EE0}"
        label: "Auslastung"
        value: Math.round(SystemService.cpuPercent) + "%"
    }
    MeterBar {
        width: root.width
        value: SystemService.cpuPercent / 100
    }

    // Per-core mini bar chart -- not in either prompt's spec (the compact
    // widget only ever showed the aggregate), added so "system monitor"
    // means more than the same one number in a bigger box.
    Row {
        width: root.width
        height: root._coreBarMaxHeight
        spacing: 3
        visible: SystemService.cpuCorePercents.length > 0

        Repeater {
            model: SystemService.cpuCorePercents

            Rectangle {
                id: coreBar
                required property real modelData
                width: Math.max(2, (root.width - (SystemService.cpuCorePercents.length - 1) * 3) / SystemService.cpuCorePercents.length)
                anchors.bottom: parent.bottom
                height: root._coreBarMaxHeight * Math.max(0.05, coreBar.modelData / 100)
                radius: 1
                color: Colors.primary
                opacity: 0.4 + 0.6 * (coreBar.modelData / 100)
                Behavior on height { NumberAnimation { duration: Style.anim200 } }
            }
        }
    }

    Text {
        topPadding: 8
        text: "GPU"
        visible: SystemService.gpuAvailable
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Column {
        width: root.width
        spacing: 8
        visible: SystemService.gpuAvailable

        MenuRow {
            width: root.width
            iconGlyph: "\u{F08AE}"
            label: "Auslastung"
            value: Math.round(SystemService.gpuPercent) + "% " + SystemService.gpuTempC + "°"
        }
        MeterBar {
            width: root.width
            value: SystemService.gpuPercent / 100
        }
        WideRow {
            width: root.width
            iconGlyph: "\u{F035B}"
            label: "VRAM"
            value: SystemService.gpuVramUsedGiB.toFixed(1) + " / " + SystemService.gpuVramTotalGiB.toFixed(1) + " GiB"
        }
        MeterBar {
            width: root.width
            value: SystemService.gpuVramTotalGiB > 0 ? SystemService.gpuVramUsedGiB / SystemService.gpuVramTotalGiB : 0
        }
    }

    Text {
        topPadding: 8
        text: "ARBEITSSPEICHER"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    WideRow {
        width: root.width
        iconGlyph: "\u{F035B}"
        label: "Belegt"
        value: SystemService.memUsedGiB.toFixed(1) + " / " + SystemService.memTotalGiB.toFixed(1) + " GiB"
    }
    MeterBar {
        width: root.width
        value: SystemService.memPercent / 100
    }

    Text {
        topPadding: 4
        text: "Uptime " + SystemService.uptimeText + "  ·  Load " + SystemService.loadAvg.map(n => n.toFixed(2)).join(" ")
        font.family: Style.textFont
        font.pixelSize: Style.fontTiny
        color: Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.7)
    }
}
