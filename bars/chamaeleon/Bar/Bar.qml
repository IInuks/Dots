import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Top bar (deliberately top, not bottom/dock/floating like the sibling
// bars): mango tags left, clock centered, one control-center trigger on
// the right whose glyph mirrors the currently active theme mode -- the
// bar itself visibly reflects its own adaptive state.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Metrics.barHeight
    exclusiveZone: Metrics.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "chamaeleon-bar"

    readonly property var _modeGlyph: ({ dark: "🌙", light: "☀", auto: "🕐", adaptive: "💧" })[Config.mode] || "🌙"

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.ink, Theme.barAlpha)
    }

    Rectangle {
        id: launcherBtn
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Metrics.barMargin
        width: 30
        height: Metrics.barHeight - 8
        radius: Theme.rSmall
        color: Popups.isOpen("launcher") ? Qt.alpha(Theme.accent, 0.25) : (launcherHover.containsMouse ? Theme.panelRaised : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.tFast } }

        Text {
            anchors.centerIn: parent
            text: "⊞"
            color: Theme.text
            font.pixelSize: 14
        }

        MouseArea {
            id: launcherHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const p = launcherBtn.mapToItem(null, launcherBtn.width / 2, 0);
                Popups.toggleAt("launcher", p.x);
            }
        }
    }

    Row {
        id: tagsRow
        visible: Config.showTags
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: launcherBtn.right
        anchors.leftMargin: Metrics.barMargin
        spacing: 4

        Repeater {
            model: MangoIpc.tagsFor(bar.screen ? bar.screen.name : "")
            delegate: Rectangle {
                id: tagDot
                required property var modelData
                width: 18; height: 18; radius: Theme.rSmall - 2
                color: tagDot.modelData.is_active ? Theme.accent : Qt.alpha(Theme.textFaint, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: (tagDot.modelData.index + 1)
                    color: tagDot.modelData.is_active ? Theme.ink : Theme.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MangoIpc.viewTag(bar.screen ? bar.screen.name : "", tagDot.modelData.index)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(new Date(), "ddd dd.MM. hh:mm")
        color: Theme.text
        font.family: Metrics.fontFamily
        font.pixelSize: 12
        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatDateTime(new Date(), "ddd dd.MM. hh:mm") }
    }

    Rectangle {
        id: notifBtn
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: controlBtn.left
        anchors.rightMargin: 6
        width: 30
        height: Metrics.barHeight - 8
        radius: Theme.rSmall
        color: Popups.isOpen("notifications") ? Qt.alpha(Theme.accent, 0.25) : (notifHover.containsMouse ? Theme.panelRaised : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.tFast } }

        Text {
            anchors.centerIn: parent
            text: "🔔"
            font.pixelSize: 12
        }

        Rectangle {
            visible: NotifyHub.unread > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 2
            width: 8; height: 8; radius: 4
            color: Theme.bad
        }

        MouseArea {
            id: notifHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const p = notifBtn.mapToItem(null, notifBtn.width / 2, 0);
                Popups.toggleAt("notifications", p.x);
            }
        }
    }

    Rectangle {
        id: controlBtn
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Metrics.barMargin
        width: 42
        height: Metrics.barHeight - 8
        radius: Theme.rSmall
        color: Popups.isOpen("settings") ? Qt.alpha(Theme.accent, 0.25) : (hoverArea.containsMouse ? Theme.panelRaised : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.tFast } }

        Text {
            anchors.centerIn: parent
            text: bar._modeGlyph
            font.pixelSize: 15
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const p = controlBtn.mapToItem(null, controlBtn.width / 2, 0);
                Popups.toggleAt("settings", p.x);
            }
        }
    }
}
