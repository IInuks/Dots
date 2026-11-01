import QtQuick
import "../../"

// Bar prompt section 4, "memory" row: usage%, icon U+F035B, from
// /proc/meminfo via SystemService. Not clickable per spec's table.
Row {
    id: root
    spacing: 4

    Text {
        font.family: Style.iconFont
        font.pixelSize: 14
        color: Colors.primary
        text: "\u{F035B}"
    }
    Text {
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Colors.tertiary
        text: Math.round(SystemService.memPercent) + "%"
    }
}
