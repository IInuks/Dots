import QtQuick
import Quickshell.Bluetooth
import "../../"

// Bar prompt section 4, "bluetooth" row: battery of the first connected
// device with battery data, icon U+F00AF. Hidden entirely without one, per
// spec ("ausgeblendet ohne Daten"). Native Quickshell.Bluetooth service --
// same BluetoothDevice.connected/.batteryAvailable/.battery source
// bars/lucid/Panels/BluetoothSection.qml already proved on this system.
// `battery` is a 0..1 fraction, same convention as Pipewire's `audio.volume`
// and UPower's `percentage`. Click opens the Bluetooth dropdown (menus
// prompt 1.3, Stage 3) -- the click catcher is a sibling of the Row, not a
// child of it: a Row child can't use `anchors.fill` (Row positions children
// itself and warns/no-ops on that), so the click area lives one level up.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var device: {
        const devs = root.adapter ? root.adapter.devices.values : [];
        return devs.find(d => d.connected && d.batteryAvailable) || null;
    }
    readonly property bool available: !!root.device

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: "\u{F00AF}"
        }
        Text {
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: root.device ? Math.round(root.device.battery * 100) + "%" : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("bluetooth")
    }
}
