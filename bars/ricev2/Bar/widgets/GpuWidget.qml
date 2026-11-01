import QtQuick
import "../../"

// Bar prompt section 4, "gpu" row: usage% + temp°, icon U+F08AE, via
// SystemService's nvidia-smi poll. Not clickable per spec's table ("–" in
// the Klick column). Collapses if nvidia-smi isn't present/failing, same
// present-gating WidgetSlot.qml applies to wifi/bluetooth/brightness/
// battery.
Row {
    id: root
    spacing: 4

    readonly property bool available: SystemService.gpuAvailable

    Text {
        font.family: Style.iconFont
        font.pixelSize: 14
        color: Colors.primary
        text: "\u{F08AE}"
    }
    Text {
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Colors.tertiary
        text: Math.round(SystemService.gpuPercent) + "% " + SystemService.gpuTempC + "°"
    }
}
