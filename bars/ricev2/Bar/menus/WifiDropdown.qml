import QtQuick
import Quickshell.Networking
import "../../"

// WLAN dropdown content (menus prompt 1.2). Uses Quickshell.Networking
// (same service the bar's WifiWidget.qml already reads), not the README's
// original nmcli-Process plan -- see WifiWidget.qml's header comment for
// why. Password entry goes through WifiNetwork.connectWithPsk(); nothing
// here shells out to nmcli or iwctl directly.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 8

    readonly property var wifiDevice: {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === DeviceType.Wifi) || null;
    }
    readonly property var networks: {
        const nets = root.wifiDevice ? root.wifiDevice.networks.values : [];
        return nets.slice().sort((a, b) => b.signalStrength - a.signalStrength);
    }
    readonly property var connectedNetwork: root.networks.find(n => n.connected) || null

    property var pskTarget: null
    // Exclusive keyboard focus (BarShell.qml) only while the password field
    // actually needs typed input -- see DropdownState.keyboardWanted.
    onPskTargetChanged: DropdownState.keyboardWanted = !!root.pskTarget
    Component.onDestruction: {
        DropdownState.keyboardWanted = false;
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = false;
    }

    // Quickshell's WifiDevice exposes `scannerEnabled` (write) but no
    // "scan finished" signal/property to watch (checked against this
    // Quickshell version's qmltypes) -- so "Scanning..." is approximated as
    // a fixed window after enabling the scanner, not a real scan-complete
    // event, per spec 1.2's "Während des Scans steht dort 'Scanning...'".
    property bool _scanning: false
    Timer {
        id: scanWindow
        interval: 2500
        onTriggered: root._scanning = false
    }
    Component.onCompleted: {
        if (root.wifiDevice) {
            root.wifiDevice.scannerEnabled = true;
            root._scanning = true;
            scanWindow.start();
        }
    }

    function _signalIcon(strength) {
        if (strength < 25)
            return "\u{F091F}";
        if (strength < 50)
            return "\u{F0922}";
        if (strength < 75)
            return "\u{F0925}";
        return "\u{F0928}";
    }
    function _securityLabel(net) {
        return net.security === WifiSecurityType.Open ? "Offen" : "Gesichert";
    }
    function _activate(net) {
        if (net.connected) {
            net.disconnect();
            root.pskTarget = null;
        } else if (net.known || net.security === WifiSecurityType.Open) {
            net.connect();
            root.pskTarget = null;
        } else {
            root.pskTarget = (root.pskTarget === net) ? null : net;
        }
    }

    Text {
        text: "WIFI"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    MenuRow {
        visible: !!root.connectedNetwork
        width: parent.width
        iconGlyph: "\u{F0928}"
        iconColor: Colors.primary
        label: root.connectedNetwork ? root.connectedNetwork.name : ""
        labelColor: Colors.primary
        value: root.connectedNetwork ? Math.round(root.connectedNetwork.signalStrength) + "%" : ""
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
    }

    Text {
        font.family: Style.textFont
        font.pixelSize: root._scanning ? 11 : 10
        color: Colors.tertiary
        text: root._scanning ? "Scanning..." : "AVAILABLE"
    }

    Repeater {
        model: root.networks

        Column {
            id: netRow
            required property var modelData
            width: root.width
            spacing: 4

            MenuRow {
                width: parent.width
                iconGlyph: netRow.modelData.known ? "\u{F0E1E}" : root._signalIcon(netRow.modelData.signalStrength)
                iconColor: netRow.modelData.known ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.7) : Colors.tertiary
                label: netRow.modelData.name
                labelColor: Colors.backgroundText
                bold: netRow.modelData.connected
                value: Math.round(netRow.modelData.signalStrength) + "%"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root._activate(netRow.modelData)
                }
            }
            Text {
                x: 26
                font.family: Style.textFont
                font.pixelSize: 11
                color: Colors.tertiary
                text: root._securityLabel(netRow.modelData) + (netRow.modelData.connected ? " · verbunden" : "")
            }

            PasswordField {
                width: parent.width
                open: root.pskTarget === netRow.modelData
                onCancelled: root.pskTarget = null
                onConnectRequested: password => {
                    netRow.modelData.connectWithPsk(password);
                    root.pskTarget = null;
                }
            }
        }
    }

    Text {
        visible: root.networks.length === 0 && !root._scanning
        font.family: Style.textFont
        font.pixelSize: 11
        color: Colors.tertiary
        text: "Keine Netzwerke gefunden"
    }
}
