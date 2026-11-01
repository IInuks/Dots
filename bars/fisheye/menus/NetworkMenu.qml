import QtQuick
import Quickshell.Networking
import ".."
import "../widgets/common"
import "../widgets/segment"

// Wired status (read-only, a cable is either plugged in or it isn't) + Wi-Fi
// enable toggle + network list, opened from NetworkModule. Password entry
// for an unknown secured network swaps in a second row under it instead of
// a separate dialog -- same inline-second-state trick PowerMenu uses for
// its "SICHER?" confirm, since Quickshell has no native dialog to reach for.
Item {
    id: root

    readonly property var wiredDevice: root._deviceOf(DeviceType.Wired)
    readonly property var wifiDevice: root._deviceOf(DeviceType.Wifi)
    readonly property var networks: {
        const nets = root.wifiDevice ? root.wifiDevice.networks.values : [];
        return nets.slice().sort((a, b) => b.signalStrength - a.signalStrength);
    }

    property var pskTarget: null
    property string pskText: ""

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
            root.pskText = "";
        }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                visible: !!root.wiredDevice
                spacing: 6

                Text {
                    text: "KABEL"
                    color: Theme.surfaceInk
                    opacity: 0.7
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    width: 50
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.wiredDevice && root.wiredDevice.connected ? "VERBUNDEN" : "GETRENNT"
                    color: root.wiredDevice && root.wiredDevice.connected ? Theme.success : Theme.surfaceInk
                    opacity: root.wiredDevice && root.wiredDevice.connected ? 1 : 0.5
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.bevelDark
                visible: !!root.wiredDevice
            }

            Row {
                width: parent.width

                Text {
                    text: "WLAN"
                    color: Theme.surfaceInk
                    opacity: 0.7
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    width: parent.width - 34
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToggleSwitch {
                    checked: Networking.wifiEnabled
                    onToggled: checked => Networking.wifiEnabled = checked
                }
            }

            Repeater {
                model: Networking.wifiEnabled ? root.networks : []

                Column {
                    id: netRow
                    required property var modelData
                    width: col.width
                    spacing: 4

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: netRow.modelData.name
                            color: Theme.surfaceInk
                            font.pixelSize: 10
                            font.bold: netRow.modelData.connected
                            elide: Text.ElideRight
                            width: 100
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        SegmentBar {
                            width: 40
                            anchors.verticalCenter: parent.verticalCenter
                            segmentCount: 4
                            value: netRow.modelData.signalStrength / 100
                        }
                        Text {
                            text: netRow.modelData.connected ? "VERBUNDEN" : (!netRow.modelData.known && netRow.modelData.security !== WifiSecurityType.Open ? "GESICHERT" : "")
                            color: netRow.modelData.connected ? Theme.success : Theme.surfaceInk
                            opacity: netRow.modelData.connected ? 1 : 0.5
                            font.pixelSize: 8
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(netRow.modelData)
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6
                        visible: root.pskTarget === netRow.modelData

                        Rectangle {
                            width: parent.width - 60
                            height: 18
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.bevelDark

                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 3
                                color: Theme.surfaceInk
                                font.pixelSize: 9
                                echoMode: TextInput.Password
                                clip: true
                                focus: root.pskTarget === netRow.modelData
                                onTextChanged: root.pskText = text
                                Keys.onReturnPressed: {
                                    netRow.modelData.connectWithPsk(root.pskText);
                                    root.pskTarget = null;
                                }
                            }
                        }
                        Rectangle {
                            width: 54
                            height: 18
                            radius: Theme.radius * 0.5
                            color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "VERB."
                                color: Theme.accentInk
                                font.pixelSize: 9
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    netRow.modelData.connectWithPsk(root.pskText);
                                    root.pskTarget = null;
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: Networking.wifiEnabled && root.networks.length === 0
                text: "KEINE NETZWERKE"
                color: Theme.surfaceInk
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 1
            }
        }
    }
}
