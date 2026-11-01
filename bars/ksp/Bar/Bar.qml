import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Top bar styled after KSP's toolbar: a launcher badge, mango tags as
// numbered "stage" badges (active stage pulses like the next-stage
// highlight in the real game), a chronometer readout centered, and a
// signal gauge + AppLauncher-style badges (comms log, control center) on
// the right. The whole bar slides/fades in on mount instead of just
// appearing.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Metrics.barHeight
    exclusiveZone: Metrics.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "ksp-bar"

    property bool colonOn: true
    Timer { interval: 500; running: true; repeat: true; onTriggered: bar.colonOn = !bar.colonOn }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        y: -Metrics.barHeight
        Component.onCompleted: mount.start()
        SequentialAnimation {
            id: mount
            PauseAnimation { duration: 80 }
            ParallelAnimation {
                NumberAnimation { target: content; property: "y"; to: 0; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                NumberAnimation { target: content; property: "opacity"; to: 1; duration: 320 }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.ink, Theme.barAlpha)
        }

        HazardStripe {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            stripeColor: Theme.accent
            stripeWidth: 5
        }

        // -- Launcher trigger --
        Rectangle {
            id: launcherBtn
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Metrics.barMargin
            width: 30
            height: Metrics.barHeight - 10
            radius: Theme.rSmall
            color: Popups.isOpen("launcher") ? Qt.alpha(Theme.accent, 0.25) : (launcherHover.containsMouse ? Theme.panelRaised : "transparent")
            border.width: 1
            border.color: Qt.alpha(Theme.accent, Popups.isOpen("launcher") ? 0.7 : 0.25)
            Behavior on color { ColorAnimation { duration: Theme.tFast } }
            Behavior on border.color { ColorAnimation { duration: Theme.tFast } }
            scale: launcherHover.containsMouse ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }

            Text {
                anchors.centerIn: parent
                text: "🚀"
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

        // -- Stage badges (mango tags) --
        Row {
            id: tagsRow
            visible: Config.showTags
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: launcherBtn.right
            anchors.leftMargin: 12
            spacing: 6

            Repeater {
                model: MangoIpc.tagsFor(bar.screen ? bar.screen.name : "")
                delegate: Item {
                    id: stageBadge
                    required property var modelData
                    width: 22; height: 22

                    readonly property bool active: stageBadge.modelData.is_active

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 8
                        height: parent.height + 8
                        radius: (width) / 2
                        color: "transparent"
                        border.width: 1.5
                        border.color: Theme.accent
                        visible: stageBadge.active
                        opacity: 0
                        SequentialAnimation on opacity {
                            running: stageBadge.active
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.7; duration: 550; easing.type: Easing.OutCubic }
                            NumberAnimation { to: 0; duration: 550; easing.type: Easing.InCubic }
                        }
                        scale: stageBadge.active ? 1 : 0.6
                        Behavior on scale { NumberAnimation { duration: Theme.tMed } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: stageBadge.active ? Theme.accent : Qt.alpha(Theme.textFaint, 0.16)
                        border.width: stageBadge.active ? 0 : 1
                        border.color: Qt.alpha(Theme.textFaint, 0.4)
                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        Text {
                            anchors.centerIn: parent
                            text: (stageBadge.modelData.index + 1)
                            color: stageBadge.active ? Theme.ink : Theme.textFaint
                            font.family: Metrics.fontMono
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MangoIpc.viewTag(bar.screen ? bar.screen.name : "", stageBadge.modelData.index)
                    }
                }
            }
        }

        // -- Chronometer --
        Column {
            anchors.centerIn: parent
            spacing: -2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), "ddd dd.MM").toUpperCase()
                color: Theme.textFaint
                font.family: Metrics.fontMono
                font.pixelSize: 8
                font.letterSpacing: 1.5
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), bar.colonOn ? "hh:mm:ss" : "hh mm ss")
                color: Theme.accent
                font.family: Metrics.fontMono
                font.pixelSize: 14
                font.bold: true
                Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatTime(new Date(), bar.colonOn ? "hh:mm:ss" : "hh mm ss") }
            }
        }

        // -- Right cluster: signal gauge + comms log + control center --
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Metrics.barMargin
            spacing: 8

            Gauge {
                id: signalGauge
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 12
                segments: 6
                value: MangoIpc.monitors.length > 0 ? 1 : 0.15
            }

            Rectangle {
                id: telemetryBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: Metrics.barHeight - 10
                radius: Theme.rSmall
                color: Popups.isOpen("telemetry") ? Qt.alpha(Theme.accent, 0.25) : (telemetryHover.containsMouse ? Theme.panelRaised : "transparent")
                border.width: 1
                border.color: Qt.alpha(Theme.accent, Popups.isOpen("telemetry") ? 0.7 : 0.25)
                Behavior on color { ColorAnimation { duration: Theme.tFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.tFast } }
                scale: telemetryHover.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: "🛰"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: telemetryHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const p = telemetryBtn.mapToItem(null, telemetryBtn.width / 2, 0);
                        Popups.toggleAt("telemetry", p.x);
                    }
                }
            }

            Rectangle {
                id: notifBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: Metrics.barHeight - 10
                radius: Theme.rSmall
                color: Popups.isOpen("notifications") ? Qt.alpha(Theme.accent, 0.25) : (notifHover.containsMouse ? Theme.panelRaised : "transparent")
                border.width: 1
                border.color: Qt.alpha(Theme.accent, Popups.isOpen("notifications") ? 0.7 : 0.25)
                Behavior on color { ColorAnimation { duration: Theme.tFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.tFast } }
                scale: notifHover.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: "📡"
                    font.pixelSize: 13
                }

                Rectangle {
                    visible: NotifyHub.unread > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.rightMargin: 1
                    width: 8; height: 8; radius: 4
                    color: Theme.bad
                    border.width: 1
                    border.color: Theme.ink

                    SequentialAnimation on scale {
                        running: NotifyHub.unread > 0
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.3; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                    }
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
                width: 30
                height: Metrics.barHeight - 10
                radius: Theme.rSmall
                color: Popups.isOpen("settings") ? Qt.alpha(Theme.accent, 0.25) : (hoverArea.containsMouse ? Theme.panelRaised : "transparent")
                border.width: 1
                border.color: Qt.alpha(Theme.accent, Popups.isOpen("settings") ? 0.7 : 0.25)
                Behavior on color { ColorAnimation { duration: Theme.tFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.tFast } }
                scale: hoverArea.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                rotation: Popups.isOpen("settings") ? 45 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    rotation: -parent.rotation
                    text: "⚙"
                    color: Theme.text
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

        CrtOverlay { anchors.fill: parent }
    }
}
