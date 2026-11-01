import QtQuick
import Quickshell.Bluetooth
import "../../"

// Bluetooth dropdown content (menus prompt 1.3): connected devices only,
// icon + name + battery -- same Bluetooth.defaultAdapter service the bar's
// BluetoothWidget.qml already reads. No enable toggle or pairing list here;
// the prompt's section 1.3 only asks for the connected-devices row.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 10

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: {
        const devs = root.adapter ? root.adapter.devices.values : [];
        return devs.filter(d => d.connected);
    }

    Text {
        text: "BLUETOOTH DEVICES"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Repeater {
        model: root.connectedDevices

        MenuRow {
            id: devRow
            required property var modelData
            width: root.width
            iconGlyph: "\u{F00AF}"
            iconColor: Colors.primary
            label: devRow.modelData.deviceName || devRow.modelData.name
            labelColor: Colors.backgroundText
            value: devRow.modelData.batteryAvailable ? Math.round(devRow.modelData.battery * 100) + "%" : ""
        }
    }

    Text {
        visible: root.connectedDevices.length === 0
        font.family: Style.textFont
        font.pixelSize: 11
        color: Colors.tertiary
        text: "Keine verbundenen Geräte"
    }
}
