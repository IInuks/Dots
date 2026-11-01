import QtQuick
import Quickshell.Services.UPower
import "../../"

// Bar prompt section 4, "battery" row: % only, icon by charge stage (7
// discharging / 8 charging codepoints from the spec table), special colors
// while charging or under 15%. Hidden on any machine with no laptop
// battery (this desktop included -- checked, /sys/class/power_supply/ is
// empty here). Native Quickshell.Services.UPower service, same
// UPower.displayDevice/.isLaptopBattery/.isPresent/.percentage/.state
// source bars/lucid/Panels/BatteryRow.qml already proved on this system.
//
// The spec gives 7/8 codepoints per state but not their exact percent
// breakpoints, so they're bucketed evenly across 0-100% (7 buckets ~14.3
// pts wide, 8 buckets 12.5 pts wide) in the same low-to-high order the
// prompt lists them in.
Row {
    id: root
    spacing: 4

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!(root.device && root.device.isLaptopBattery && root.device.isPresent)
    readonly property bool charging: root.available && root.device.state === UPowerDeviceState.Charging
    readonly property int _percent: root.available ? Math.round(root.device.percentage * 100) : 0

    readonly property var _dischargeIcons: ["\u{F008E}", "\u{F007B}", "\u{F007D}", "\u{F007F}", "\u{F0081}", "\u{F0082}", "\u{F0079}"]
    readonly property var _chargeIcons: ["\u{F089C}", "\u{F0086}", "\u{F0087}", "\u{F0088}", "\u{F089D}", "\u{F0089}", "\u{F008B}", "\u{F0085}"]

    readonly property string _iconGlyph: {
        const icons = root.charging ? root._chargeIcons : root._dischargeIcons;
        const idx = Math.min(icons.length - 1, Math.floor(root._percent / (100 / icons.length)));
        return icons[idx];
    }

    readonly property color _iconColor: {
        if (root.charging)
            return Qt.rgba(0.4, 0.95, 0.6, 1);
        if (root._percent < 15)
            return Qt.rgba(0.95, 0.5, 0.4, 1);
        return Colors.primary;
    }

    Text {
        font.family: Style.iconFont
        font.pixelSize: 14
        color: root._iconColor
        text: root._iconGlyph
    }
    Text {
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Colors.tertiary
        text: root._percent + "%"
    }
}
