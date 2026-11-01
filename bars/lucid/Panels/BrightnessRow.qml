import QtQuick
import "../"
import "../Bar"

// Screen brightness via SystemService (brightnessctl -- no Quickshell-
// native brightness service exists). Collapses entirely when no backlight
// device is found, same present-gating as BatteryRow.qml.
Row {
    id: root
    width: parent.width
    spacing: 8
    visible: SystemService.brightnessAvailable

    Icon {
        id: icon
        glyph: "brightness_6"
        fallback: "☼"
        anchors.verticalCenter: parent.verticalCenter
    }
    Slider {
        width: root.width - icon.width - root.spacing
        anchors.verticalCenter: parent.verticalCenter
        value: SystemService.brightness
        onMoved: v => SystemService.setBrightness(v)
    }
}
