import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    Component.onCompleted: { Network.refresh(); Network.scan(); }

    Tile {
        order: 1
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Icon { name: Network.icon; size: 22; color: Network.connected ? Theme.accent : Theme.textDim }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { text: Network.label; font.weight: Font.DemiBold }
                Txt {
                    text: !Network.nmRunning ? "NetworkManager is not running" + (Network.wired ? " · " + Network.wiredName + " up" : "")
                        : Network.ssid !== "" ? "Signal " + Network.signal + "%" : (Network.wired ? Network.wiredName : "")
                    color: Theme.textDim
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                visible: Network.nmRunning
                icon: "refresh"
                onClicked: Network.scan()
            }
            Rectangle {
                visible: Network.nmRunning
                implicitWidth: 44
                implicitHeight: 24
                radius: 12
                color: Network.wifiEnabled ? Theme.accent : Theme.track
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: Network.wifiEnabled ? parent.width - width - 3 : 3
                    color: Network.wifiEnabled ? Theme.accentInk : Theme.text
                    Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 2 } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Network.setWifi(!Network.wifiEnabled) }
            }
        }
    }

    Tile {
        order: 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 2
            model: Network.nmRunning && Network.wifiEnabled ? Network.networks : []
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { width: 3; contentItem: Rectangle { implicitWidth: 3; radius: 1.5; color: Theme.textFaint } }
            delegate: ListRow {
                required property var modelData
                width: list.width
                icon: "wifi"
                label: modelData.ssid
                trailing: (modelData.secure ? "🔒 " : "") + modelData.signal + "%"
                selected: modelData.inUse
                onClicked: modelData.inUse ? Network.disconnect() : Network.connect(modelData)
            }
        }

        Txt {
            anchors.centerIn: parent
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: list.count === 0
            color: Theme.textDim
            text: !Network.nmRunning ? "Start NetworkManager to manage Wi-Fi here."
                : !Network.wifiEnabled ? "Wi-Fi is off."
                : Network.scanning ? "Scanning…" : "No networks found."
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Txt { text: Network.lastError; color: Theme.danger; font.pixelSize: Theme.fontTiny; Layout.fillWidth: true }
        ListRow {
            Layout.preferredWidth: 150
            icon: "terminal"
            label: "Open nmtui"
            onClicked: { Ui.terminal(["-e", "nmtui"]); Ui.controlCenterOpen = false; }
        }
    }
}
