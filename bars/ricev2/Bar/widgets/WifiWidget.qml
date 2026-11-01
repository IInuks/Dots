import QtQuick
import Quickshell.Networking
import "../../"

// Bar prompt section 4, "wifi" row: SSID, icon by signal-strength quartile
// (<25 F091F, <50 F0922, <75 F0925, else F0928). Hidden without a connected
// Wi-Fi network, per spec. Native Quickshell.Networking service -- same
// Networking.devices/DeviceType.Wifi/network.signalStrength source
// bars/lucid/Panels/WifiSection.qml already proved on this system. This is
// a better fit than README.md's original "WLAN-Backend" plan (raw `nmcli`
// Process calls) since it's event-driven (no manual polling) and NM-backed
// either way. Click opens the WLAN dropdown (menus prompt 1.2, Stage 3) --
// the click catcher is a sibling of the Row, not a child of it: a Row child
// can't use `anchors.fill` (Row positions children itself and warns/no-ops
// on that), so the click area lives one level up.
Item {
    id: root

    readonly property var wifiDevice: {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === DeviceType.Wifi) || null;
    }
    readonly property var network: {
        const nets = root.wifiDevice ? root.wifiDevice.networks.values : [];
        return nets.find(n => n.connected) || null;
    }
    readonly property bool available: !!root.network

    readonly property string _iconGlyph: {
        if (!root.network)
            return "";
        const s = root.network.signalStrength;
        if (s < 25)
            return "\u{F091F}";
        if (s < 50)
            return "\u{F0922}";
        if (s < 75)
            return "\u{F0925}";
        return "\u{F0928}";
    }

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
            text: root._iconGlyph
        }
        Text {
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: root.network ? root.network.name : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("wifi")
    }
}
