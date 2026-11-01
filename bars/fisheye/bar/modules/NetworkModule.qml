import QtQuick
import Quickshell.Networking
import "../.."
import "../../widgets/segment"

// Connection status as a SegmentBar. Wired takes priority over Wi-Fi when
// both exist (this dev machine is a desktop on Ethernet with an unused
// Wi-Fi card, and only checking Wi-Fi would permanently show "no signal"
// despite being online) -- a wired link has no signal strength concept, so
// it just lights the bar fully rather than trying to fake a percentage.
// Click opens NetworkMenu (Bar.qml owns the PopupShell), same split every
// other popup-backed module in this bar uses.
Item {
    id: root

    signal clicked

    readonly property var wiredDevice: root._deviceOf(DeviceType.Wired)
    readonly property var wifiDevice: root._deviceOf(DeviceType.Wifi)
    readonly property bool wiredConnected: !!(root.wiredDevice && root.wiredDevice.connected)
    readonly property var activeWifiNetwork: {
        const nets = root.wifiDevice ? root.wifiDevice.networks.values : [];
        return nets.find(n => n.connected) || null;
    }
    readonly property real level: {
        if (root.wiredConnected)
            return 1;
        if (root.activeWifiNetwork)
            return root.activeWifiNetwork.signalStrength / 100;
        return 0;
    }

    function _deviceOf(type) {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === type) || null;
    }

    implicitWidth: 22
    implicitHeight: 12

    SegmentBar {
        anchors.fill: parent
        segmentCount: 4
        value: root.level
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
