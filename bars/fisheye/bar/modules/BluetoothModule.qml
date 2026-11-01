import QtQuick
import Quickshell.Bluetooth
import "../.."
import "../../widgets/segment"

// Small LCD tile, same visual language as a WorkspacesModule slot: lit
// when the adapter is on, with a SevenSegment count of connected devices
// when there's at least one. No adapter -> the whole module collapses
// (implicitWidth 0), same pattern BatteryModule uses for "no battery".
// Click opens BluetoothMenu (Bar.qml owns the PopupShell).
Item {
    id: root

    signal clicked

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasAdapter: !!root.adapter
    readonly property bool enabled: root.hasAdapter && root.adapter.enabled
    readonly property int connectedCount: {
        const devs = Bluetooth.devices ? Bluetooth.devices.values : [];
        return devs.filter(d => d.connected).length;
    }

    visible: root.hasAdapter
    implicitWidth: root.hasAdapter ? tile.width : 0
    implicitHeight: tile.height

    Rectangle {
        id: tile
        width: 18
        height: 18
        radius: Theme.radius * 0.6
        color: root.enabled ? Theme.accent : "transparent"
        border.width: 1
        border.color: root.enabled ? Theme.accent : Theme.bevelDark
        Behavior on color {
            ColorAnimation {
                duration: Theme.durBase
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durBase
            }
        }

        SevenSegment {
            anchors.centerIn: parent
            char: String(Math.min(root.connectedCount, 9))
            digitHeight: 10
            onColor: root.enabled ? Theme.accentInk : Theme.segmentOn
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
