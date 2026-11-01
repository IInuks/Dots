import QtQuick
import Quickshell.Services.UPower
import "../"
import "../Bar"

// Battery percent + charging state via Quickshell's native UPower service,
// same UPower.displayDevice source bars/fisheye/bar/modules/BatteryModule.
// qml already proved on this system. Collapses entirely on battery-less
// desktop hardware (visible: root.present), same as fisheye's.
Row {
    id: root
    width: parent.width
    spacing: 8

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!(root.device && root.device.isLaptopBattery && root.device.isPresent)
    readonly property bool charging: root.present && root.device.state === UPowerDeviceState.Charging

    visible: root.present

    Icon {
        glyph: root.charging ? "battery_charging_full" : "battery_full"
        fallback: root.charging ? "⚡" : "▮"
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        text: root.present ? Math.round(root.device.percentage * 100) + "%" : ""
        color: Theme.surfaceInk
        font.pixelSize: 12
        font.family: Theme.uiFontFamily
        anchors.verticalCenter: parent.verticalCenter
    }
}
