import QtQuick
import "../"
import "../Bar"

// CPU / RAM / Disk, compact three-up readout sourced from SystemService's
// /proc + df polling (same approach as bars/klasic/SystemStats.qml and
// bars/shellbar/SysMonData.qml).
Row {
    id: root
    width: parent.width
    spacing: 16

    Row {
        spacing: 4
        Icon { glyph: "speed"; fallback: "▪"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Math.round(SystemService.cpuPercent) + "%"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Row {
        spacing: 4
        Icon { glyph: "memory"; fallback: "▫"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: SystemService.ramUsedGB.toFixed(1) + "/" + SystemService.ramTotalGB.toFixed(0) + "GB"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Row {
        spacing: 4
        Icon { glyph: "storage"; fallback: "▤"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Math.round(SystemService.diskPercent) + "%"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
