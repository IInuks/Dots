import QtQuick
import Quickshell.Networking
import "../"
import "../Bar"

// Full WLAN control -- wired status (read-only), Wi-Fi enable toggle, and
// network list, via Quickshell's native Networking service. Same
// Networking.devices/DeviceType/wifiEnabled/connectWithPsk() source
// bars/fisheye/menus/NetworkMenu.qml already proved on this system,
// restyled to this bar's Material 3 look. Password entry for an unknown
// secured network swaps in a second row beneath it -- no native dialog to
// reach for, same inline-second-state trick fisheye's NetworkMenu uses.
Column {
    id: root
    spacing: 8

    readonly property var wiredDevice: root._deviceOf(DeviceType.Wired)
    readonly property var wifiDevice: root._deviceOf(DeviceType.Wifi)
    readonly property var networks: {
        const nets = root.wifiDevice ? root.wifiDevice.networks.values : [];
        return nets.slice().sort((a, b) => b.signalStrength - a.signalStrength);
    }

    property var pskTarget: null

    function _deviceOf(type) {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === type) || null;
    }

    function activate(net) {
        if (net.connected) {
            net.disconnect();
            root.pskTarget = null;
        } else if (net.known || net.security === WifiSecurityType.Open) {
            net.connect();
            root.pskTarget = null;
        } else {
            root.pskTarget = net;
        }
    }

    Text {
        text: "WLAN"
        color: Theme.surfaceInk
        font.pixelSize: 12
        font.bold: true
        font.family: Theme.uiFontFamily
    }

    Row {
        width: parent.width
        spacing: 6
        visible: !!root.wiredDevice

        Icon { id: cableIcon; glyph: "cable"; fallback: "—"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: root.wiredDevice && root.wiredDevice.connected ? "Kabel verbunden" : "Kabel getrennt"
            color: root.wiredDevice && root.wiredDevice.connected ? Theme.tertiary : Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        width: parent.width
        spacing: 8

        Icon { id: wifiIcon; glyph: "wifi"; fallback: "≈"; anchors.verticalCenter: parent.verticalCenter }
        Text {
            width: parent.width - wifiIcon.width - wifiToggle.width - 2 * parent.spacing
            text: Networking.wifiEnabled ? "Aktiv" : "Aus"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
        Toggle {
            id: wifiToggle
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    Column {
        width: parent.width
        spacing: 6
        visible: Networking.wifiEnabled

        Repeater {
            model: Networking.wifiEnabled ? root.networks : []

            Column {
                id: netRow
                required property var modelData
                width: root.width
                spacing: 4

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width - 90
                        text: netRow.modelData.name
                        color: Theme.surfaceInk
                        font.pixelSize: 11
                        font.bold: netRow.modelData.connected
                        font.family: Theme.uiFontFamily
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: netRow.modelData.connected ? "verbunden" : (!netRow.modelData.known && netRow.modelData.security !== WifiSecurityType.Open ? "gesichert" : "")
                        color: netRow.modelData.connected ? Theme.tertiary : Theme.outline
                        font.pixelSize: 10
                        font.family: Theme.uiFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.activate(netRow.modelData)
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6
                    visible: root.pskTarget === netRow.modelData

                    TextField {
                        id: pskField
                        width: parent.width - 56
                        isPassword: true
                        placeholder: "Passwort"
                        onAccepted: {
                            netRow.modelData.connectWithPsk(text);
                            root.pskTarget = null;
                        }
                    }
                    Rectangle {
                        width: 48
                        height: 28
                        radius: 8
                        color: Theme.primary
                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: Theme.primaryInk
                            font.pixelSize: 11
                            font.family: Theme.uiFontFamily
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                netRow.modelData.connectWithPsk(pskField.text);
                                root.pskTarget = null;
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.networks.length === 0
            text: "Keine Netzwerke"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }
    }
}
