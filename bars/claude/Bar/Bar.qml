import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Top-anchored status bar. Left: tags. Center: the five popup
// triggers, evenly spaced so they read as a proper dock. Right: CPU +
// volume gauges, tray, clock.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors { left: true; right: true; top: true }
    implicitHeight: Metrics.barHeight
    exclusiveZone: Metrics.barHeight
    color: Qt.alpha(Chroma.ink, Chroma.barAlpha)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "claude-dock"

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.alpha(Chroma.accent, 0.18)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Metrics.barSideMargin
        anchors.rightMargin: Metrics.barSideMargin

        Tags {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        Row {
            anchors.centerIn: parent
            spacing: 22

            DockButton { glyphName: "search"; popupId: "launcher"; anchors.verticalCenter: parent.verticalCenter }
            DockButton { glyphName: "image"; popupId: "wallpapers"; anchors.verticalCenter: parent.verticalCenter }
            DockButton { glyphName: "gear"; popupId: "settings"; anchors.verticalCenter: parent.verticalCenter }
            DockButton { glyphName: "bell"; popupId: "notifications"; badgeCount: NotifyHub.unread; anchors.verticalCenter: parent.verticalCenter }
            DockButton { glyphName: "power"; popupId: "power"; anchors.verticalCenter: parent.verticalCenter }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            CpuGauge { Layout.alignment: Qt.AlignVCenter }
            VolumeGauge { Layout.alignment: Qt.AlignVCenter }
            TrayRow { Layout.alignment: Qt.AlignVCenter; hostWindow: root }
            ClockText {
                id: clockText
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    const center = clockText.mapToItem(null, clockText.width / 2, 0);
                    Popups.toggleAt("settings", center.x);
                }
            }
        }
    }
}
