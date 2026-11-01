import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../.."
import "../Spider"

PanelWindow {
    id: root

    // Von Variants { model: Quickshell.screens } in shell.qml gesetzt.
    required property var modelData
    screen: modelData

    anchors {
        left: true
        right: true
        top: true
    }

    implicitHeight: Settings.barHeight
    exclusiveZone: Settings.barHeight
    color: Colors.bg

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "simple-bar"

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Workspaces {
            id: workspaces
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        Clock {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Settings.rightClusterSpacing

            Media {
                Layout.alignment: Qt.AlignVCenter
            }

            Volume {
                Layout.alignment: Qt.AlignVCenter
                screen: root.screen
            }

            Notifications {
                Layout.alignment: Qt.AlignVCenter
            }

            SpiderTrigger {
                Layout.alignment: Qt.AlignVCenter
                screen: root.screen
            }

            Power {
                Layout.alignment: Qt.AlignVCenter
                screen: root.screen
            }
        }
    }
}
