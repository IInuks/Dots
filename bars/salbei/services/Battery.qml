pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery via UPower. Desktops: available=false → module hidden.
Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool available: device !== null && device.isLaptopBattery && device.ready
    readonly property real percent: device?.percentage ?? 0
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
                                    || device?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && percent < 0.2
    readonly property string icon: charging ? "battery_charging_full" : low ? "battery_alert" : "battery_full"
}
