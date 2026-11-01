import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth

// The "settings menu": one flyout, five tabs (Appearance / Bar / Sound /
// Network / Power). Pattern: a tab strip (Repeater) driving a Loader over
// the active tab's Component, same shape as bars/shellbar/SettingsMenu.qml.
// Network tab merges Wi-Fi (Quickshell.Networking, modeled on
// bars/shellbar/SettingsMenu.qml's wlanTab) and Bluetooth
// (Quickshell.Bluetooth, modeled on bars/fisheye/menus/BluetoothMenu.qml)
// into one tab rather than two, since chamaeleon's tab strip is already
// four-wide and neither needs a whole tab to itself.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.controlCenterWidth
    panelHeight: Metrics.controlCenterHeight

    property int activeTab: 0
    readonly property var tabs: [
        { label: "Appearance", component: appearanceTab },
        { label: "Bar", component: barTab },
        { label: "Sound", component: soundTab },
        { label: "Network", component: networkTab },
        { label: "Power", component: powerTab }
    ]

    Column {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            width: parent.width
            height: Metrics.tabBarHeight
            radius: Theme.rSmall
            color: Qt.alpha(Theme.textFaint, 0.12)

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: root.tabs
                    delegate: Rectangle {
                        id: tabBtn
                        required property var modelData
                        required property int index
                        readonly property bool active: root.activeTab === tabBtn.index
                        width: (root.panelWidth - 6 - (root.tabs.length - 1) * 3) / root.tabs.length
                        height: parent.height
                        radius: Theme.rSmall - 2
                        color: tabBtn.active ? Theme.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        Text {
                            anchors.centerIn: parent
                            text: tabBtn.modelData.label
                            color: tabBtn.active ? Theme.ink : Theme.textFaint
                            font.family: Metrics.fontFamily
                            font.pixelSize: 10
                            font.bold: tabBtn.active
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = tabBtn.index
                        }
                    }
                }
            }
        }

        Loader {
            width: parent.width
            height: parent.height - Metrics.tabBarHeight - 10
            sourceComponent: root.tabs[root.activeTab].component
        }
    }

    // -- Appearance: theme mode + accent override --
    Component {
        id: appearanceTab
        Column {
            width: parent.width
            spacing: 14

            Column {
                width: parent.width
                spacing: 6
                Text { text: "Theme"; color: Theme.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }

                readonly property var modes: [
                    { key: "dark", label: "Dark", glyph: "🌙" },
                    { key: "light", label: "Light", glyph: "☀" },
                    { key: "auto", label: "Auto", glyph: "🕐" },
                    { key: "adaptive", label: "Adaptive", glyph: "💧" }
                ]

                Grid {
                    width: parent.width
                    columns: 4
                    columnSpacing: 6
                    rowSpacing: 6

                    Repeater {
                        model: parent.parent.modes
                        delegate: Rectangle {
                            id: modeBtn
                            required property var modelData
                            readonly property bool active: Config.mode === modeBtn.modelData.key
                            width: (root.panelWidth - 24 - 18) / 4
                            height: 56
                            radius: Theme.rSmall
                            color: modeBtn.active ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.textFaint, 0.08)
                            border.width: modeBtn.active ? 1 : 0
                            border.color: Theme.accent

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modeBtn.modelData.glyph
                                    font.pixelSize: 16
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modeBtn.modelData.label
                                    color: modeBtn.active ? Theme.text : Theme.textFaint
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 9
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.setMode(modeBtn.modelData.key)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Text { text: "Accent"; color: Theme.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }

                Row {
                    spacing: 6

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.width: Config.accentOverride === "" ? 2 : 1
                        border.color: Config.accentOverride === "" ? Theme.text : Qt.alpha(Theme.textFaint, 0.4)
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: Theme.textFaint }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setAccentOverride("") }
                    }

                    Repeater {
                        model: Theme.accentSwatches
                        delegate: Rectangle {
                            id: swatch
                            required property string modelData
                            width: 22; height: 22; radius: 11
                            color: swatch.modelData
                            border.width: Config.accentOverride === swatch.modelData ? 2 : 0
                            border.color: Theme.text

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.setAccentOverride(swatch.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // -- Bar: opacity + tags visibility --
    Component {
        id: barTab
        Column {
            width: parent.width
            spacing: 14

            Column {
                width: parent.width
                spacing: 6
                Text { text: "Bar opacity"; color: Theme.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }
                Row {
                    width: parent.width
                    spacing: 10
                    Slider {
                        width: parent.width - 42
                        anchors.verticalCenter: parent.verticalCenter
                        value: Config.barAlpha
                        onMoved: v => Config.setBarAlpha(v)
                    }
                    Text {
                        width: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Config.barAlpha * 100) + "%"
                        color: Theme.text
                        font.family: Metrics.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            Row {
                width: parent.width
                Text {
                    text: "Show workspace tags"
                    color: Theme.text
                    font.family: Metrics.fontFamily
                    font.pixelSize: 12
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 34; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Config.showTags ? Theme.accent : Theme.panelRaised
                    Behavior on color { ColorAnimation { duration: Theme.tMed } }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.showTags ? parent.width - width - 3 : 3
                        color: Theme.text
                        Behavior on x { NumberAnimation { duration: Theme.tFast } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setShowTags(!Config.showTags) }
                }
            }
        }
    }

    // -- Sound: master volume + mute --
    Component {
        id: soundTab
        Item {
            width: parent.width
            height: parent.height

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool ready: !!(sink && sink.ready && sink.audio)

            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

            Column {
                width: parent.width
                spacing: 14

                Column {
                    width: parent.width
                    spacing: 6
                    Text { text: "Master volume"; color: Theme.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }
                    Row {
                        width: parent.width
                        spacing: 10
                        Slider {
                            width: parent.width - 42
                            anchors.verticalCenter: parent.verticalCenter
                            value: soundTab.ready ? soundTab.sink.audio.volume : 0
                            onMoved: v => { if (soundTab.ready) soundTab.sink.audio.volume = v; }
                        }
                        Text {
                            width: 32
                            anchors.verticalCenter: parent.verticalCenter
                            text: soundTab.ready ? Math.round(soundTab.sink.audio.volume * 100) + "%" : "--"
                            color: Theme.text
                            font.family: Metrics.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    width: parent.width
                    Text {
                        text: "Mute"
                        color: Theme.text
                        font.family: Metrics.fontFamily
                        font.pixelSize: 12
                        width: parent.width - 40
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 34; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        color: (soundTab.ready && soundTab.sink.audio.muted) ? Theme.accent : Theme.panelRaised
                        Behavior on color { ColorAnimation { duration: Theme.tMed } }
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: (soundTab.ready && soundTab.sink.audio.muted) ? parent.width - width - 3 : 3
                            color: Theme.text
                            Behavior on x { NumberAnimation { duration: Theme.tFast } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (soundTab.ready) soundTab.sink.audio.muted = !soundTab.sink.audio.muted; }
                        }
                    }
                }
            }
        }
    }

    // -- Network: Wi-Fi radio/scan/connect + Bluetooth radio/pair/connect --
    Component {
        id: networkTab
        Flickable {
            id: netTab
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            readonly property var wifiDevice: {
                const devs = Networking.devices ? Networking.devices.values : [];
                for (const d of devs) if (d.type === DeviceType.Wifi) return d;
                return null;
            }
            readonly property var btAdapter: Bluetooth.defaultAdapter
            readonly property var btDevices: netTab.btAdapter
                ? netTab.btAdapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
                : []

            function activateBt(dev) {
                if (dev.connected)
                    dev.disconnect();
                else if (dev.paired)
                    dev.connect();
                else
                    dev.pair();
            }

            Column {
                id: col
                width: parent.width
                spacing: 14

                // -- Wi-Fi --
                Column {
                    width: parent.width
                    spacing: 6

                    Row {
                        width: parent.width
                        Text {
                            text: "Wi-Fi"
                            color: Theme.textFaint
                            font.family: Metrics.fontFamily
                            font.pixelSize: 11
                            width: parent.width - 40
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 34; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: Networking.wifiEnabled ? Theme.accent : Theme.panelRaised
                            Behavior on color { ColorAnimation { duration: Theme.tMed } }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                anchors.verticalCenter: parent.verticalCenter
                                x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                                color: Theme.text
                                Behavior on x { NumberAnimation { duration: Theme.tFast } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                            }
                        }
                    }

                    Text {
                        visible: Networking.wifiEnabled && !netTab.wifiDevice
                        text: "No Wi-Fi device found"
                        color: Theme.textFaint
                        font.family: Metrics.fontFamily
                        font.pixelSize: 10
                    }

                    Repeater {
                        model: (Networking.wifiEnabled && netTab.wifiDevice) ? netTab.wifiDevice.networks.values : []

                        delegate: Column {
                            id: netRow
                            required property var modelData
                            readonly property var net: netRow.modelData
                            property bool expanded: false
                            width: parent.width
                            spacing: 2

                            Rectangle {
                                width: parent.width
                                height: 30
                                radius: Theme.rSmall - 2
                                color: (netRow.expanded || netRow.net.connected) ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.textFaint, 0.08)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        visible: netRow.net.connected
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Theme.accent
                                    }
                                    Text {
                                        text: netRow.net.name
                                        color: Theme.text
                                        font.family: Metrics.fontFamily
                                        font.pixelSize: 11
                                        width: parent.width - 44
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: Math.round(netRow.net.signalStrength) + "%"
                                        color: Theme.textFaint
                                        font.family: Metrics.fontFamily
                                        font.pixelSize: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (netRow.net.connected) { netRow.net.disconnect(); return; }
                                        if (netRow.net.known || netRow.net.security === WifiSecurityType.Open) { netRow.net.connect(); return; }
                                        netRow.expanded = !netRow.expanded;
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                visible: netRow.expanded
                                spacing: 4

                                Rectangle {
                                    width: parent.width - 72
                                    height: 24
                                    radius: Theme.rSmall - 2
                                    color: Qt.alpha(Theme.textFaint, 0.12)

                                    TextInput {
                                        id: pwField
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        echoMode: TextInput.Password
                                        color: Theme.text
                                        font.family: Metrics.fontFamily
                                        font.pixelSize: 11
                                        clip: true
                                        onAccepted: {
                                            netRow.net.connectWithPsk(pwField.text);
                                            netRow.expanded = false;
                                            pwField.text = "";
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 68; height: 24
                                    radius: Theme.rSmall - 2
                                    color: Qt.alpha(Theme.accent, 0.28)
                                    Text { anchors.centerIn: parent; text: "Connect"; color: Theme.text; font.family: Metrics.fontFamily; font.pixelSize: 10 }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            netRow.net.connectWithPsk(pwField.text);
                                            netRow.expanded = false;
                                            pwField.text = "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.textFaint, 0.15) }

                // -- Bluetooth --
                Column {
                    width: parent.width
                    spacing: 6

                    Row {
                        width: parent.width
                        Text {
                            text: "Bluetooth"
                            color: Theme.textFaint
                            font.family: Metrics.fontFamily
                            font.pixelSize: 11
                            width: parent.width - 40
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 34; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: (netTab.btAdapter && netTab.btAdapter.enabled) ? Theme.accent : Theme.panelRaised
                            Behavior on color { ColorAnimation { duration: Theme.tMed } }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                anchors.verticalCenter: parent.verticalCenter
                                x: (netTab.btAdapter && netTab.btAdapter.enabled) ? parent.width - width - 3 : 3
                                color: Theme.text
                                Behavior on x { NumberAnimation { duration: Theme.tFast } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (netTab.btAdapter) netTab.btAdapter.enabled = !netTab.btAdapter.enabled; }
                            }
                        }
                    }

                    Text {
                        visible: !netTab.btAdapter
                        text: "No Bluetooth adapter found"
                        color: Theme.textFaint
                        font.family: Metrics.fontFamily
                        font.pixelSize: 10
                    }

                    Repeater {
                        model: (netTab.btAdapter && netTab.btAdapter.enabled) ? netTab.btDevices : []

                        delegate: Rectangle {
                            id: btRow
                            required property var modelData
                            width: parent.width
                            height: 30
                            radius: Theme.rSmall - 2
                            color: btRow.modelData.connected ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.textFaint, 0.08)

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: btRow.modelData.deviceName || btRow.modelData.name
                                    color: Theme.text
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 11
                                    font.bold: btRow.modelData.connected
                                    width: parent.width - (btRow.modelData.batteryAvailable ? 108 : 64)
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    visible: btRow.modelData.batteryAvailable
                                    text: Math.round(btRow.modelData.battery * 100) + "%"
                                    color: Theme.textFaint
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: btRow.modelData.connected ? "Connected" : (btRow.modelData.paired ? "Paired" : "New")
                                    color: btRow.modelData.connected ? Theme.good : Theme.textFaint
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: netTab.activateBt(btRow.modelData)
                            }
                        }
                    }

                    Text {
                        visible: netTab.btAdapter && netTab.btAdapter.enabled && netTab.btDevices.length === 0
                        text: "No devices found"
                        color: Theme.textFaint
                        font.family: Metrics.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    // -- Power: lock/reboot/shutdown, click-then-confirm within 3s --
    Component {
        id: powerTab
        Column {
            width: parent.width
            spacing: 8

            readonly property var actions: [
                { key: "lock", label: "Lock", glyph: "🔒", cmd: ["loginctl", "lock-session"] },
                { key: "reboot", label: "Reboot", glyph: "⟳", cmd: ["systemctl", "reboot"] },
                { key: "shutdown", label: "Shutdown", glyph: "⏻", cmd: ["systemctl", "poweroff"] }
            ]

            Repeater {
                model: parent.actions
                delegate: Rectangle {
                    id: actionRow
                    required property var modelData
                    property bool armed: false
                    width: parent.width
                    height: 40
                    radius: Theme.rSmall
                    color: actionRow.armed ? Qt.alpha(Theme.bad, 0.28) : (hoverArea.containsMouse ? Theme.panelRaised : Qt.alpha(Theme.textFaint, 0.08))
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }

                    Timer {
                        id: disarmTimer
                        interval: 3000
                        onTriggered: actionRow.armed = false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.modelData.glyph
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.armed ? "Click again to confirm" : actionRow.modelData.label
                            color: Theme.text
                            font.family: Metrics.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (actionRow.armed) {
                                disarmTimer.stop();
                                Quickshell.execDetached(actionRow.modelData.cmd);
                                actionRow.armed = false;
                            } else {
                                actionRow.armed = true;
                                disarmTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
