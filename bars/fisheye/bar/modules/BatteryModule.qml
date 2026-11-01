import QtQuick
import Quickshell.Services.UPower
import "../.."
import "../../widgets/segment"

// Battery level as a SegmentBar, critical-pulsing under 15% while
// discharging. Collapses entirely on desktops with no battery (this dev
// machine has none -- couldn't visually verify charging behavior, only
// that the module correctly hides itself; re-check on real laptop
// hardware before trusting the charging-specific look).
Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!(root.device && root.device.isLaptopBattery && root.device.isPresent)
    readonly property real percentage: root.present ? root.device.percentage : 0
    readonly property bool discharging: root.present && root.device.state === UPowerDeviceState.Discharging
    readonly property bool low: root.discharging && root.percentage < 0.15

    visible: root.present
    implicitWidth: root.present ? 26 : 0
    implicitHeight: 12

    SegmentBar {
        anchors.fill: parent
        segmentCount: 5
        value: root.percentage
        critical: root.low
    }
}
