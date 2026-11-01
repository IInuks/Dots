import QtQuick
import "../../"

// Bar prompt section 4, "cpu" row: usage% + temp°, icon U+F0EE0. Click
// ("schließt offenes Dropdown") is meaningless before Stage 3 builds any
// dropdown, so it's not wired yet -- same deferral ClockWidget.qml already
// uses for its own Stage-3 click.
Row {
    id: root
    spacing: 4

    Text {
        font.family: Style.iconFont
        font.pixelSize: 14
        color: Colors.primary
        text: "\u{F0EE0}"
    }
    Text {
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Colors.tertiary
        text: Math.round(SystemService.cpuPercent) + "% " + (SystemService.cpuTempC >= 0 ? SystemService.cpuTempC + "°" : "--°")
    }
}
