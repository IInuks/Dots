pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.widgets

// Energie-Menü: Knopf gedrückt halten, bis sich der Ring füllt
MenuCard {
    id: root
    name: "power"
    originY: 1
    width: row.implicitWidth + 60
    height: 250

    readonly property var actions: [
        { icon: Icons.reload, label: "Shell neu", cmd: "reload", danger: false },
        { icon: Icons.logout, label: "Abmelden", cmd: ["mmsg", "dispatch", "quit"], danger: false },
        { icon: Icons.sleep, label: "Bereitschaft", cmd: ["loginctl", "suspend"], danger: false },
        { icon: Icons.reboot, label: "Neustart", cmd: ["loginctl", "reboot"], danger: true },
        { icon: Icons.power, label: "Ausschalten", cmd: ["loginctl", "poweroff"], danger: true }
    ]

    function run(a) {
        Hub.close()
        if (a.cmd === "reload") Quickshell.reload(false)
        else Quickshell.execDetached(a.cmd)
    }

    Column {
        anchors.centerIn: parent
        spacing: 22

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Zum Bestätigen gedrückt halten"
            color: Theme.textDim
        }

        Row {
            id: row
            spacing: 18
            Repeater {
                model: root.actions
                delegate: Column {
                    id: act
                    required property var modelData
                    required property int index
                    spacing: 10
                    property real progress: 0

                    // Einblenden nacheinander
                    opacity: root.open ? 1 : 0
                    transform: Translate { y: root.open ? 0 : 24; Behavior on y { NumberAnimation { duration: Theme.dur(420 + act.index * 60); easing.type: Easing.OutBack } } }
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(250 + act.index * 60) } }

                    NumberAnimation on progress {
                        id: fillAnim
                        running: false
                        to: 1
                        duration: 750
                        onFinished: if (act.progress >= 1) root.run(act.modelData)
                    }
                    NumberAnimation on progress {
                        id: drainAnim
                        running: false
                        to: 0
                        duration: 250
                        easing.type: Easing.OutCubic
                    }

                    Item {
                        width: 96; height: 96
                        anchors.horizontalCenter: parent.horizontalCenter
                        scale: pma.pressed ? 0.92 : pma.containsMouse ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.fill: parent
                            radius: pma.containsMouse ? 30 : 48
                            color: pma.containsMouse ? (act.modelData.danger ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Theme.accentSoft) : Theme.surface
                            Behavior on radius { NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
                        }
                        Canvas {
                            id: ring
                            anchors.fill: parent
                            property real p: act.progress
                            property color c: act.modelData.danger ? Theme.danger : Theme.accent
                            onPChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()
                                if (p <= 0) return
                                ctx.lineWidth = 5
                                ctx.lineCap = "round"
                                ctx.strokeStyle = c
                                ctx.beginPath()
                                ctx.arc(width / 2, height / 2, width / 2 - 5, -Math.PI / 2, -Math.PI / 2 + p * 2 * Math.PI)
                                ctx.stroke()
                            }
                        }
                        Glyph {
                            anchors.centerIn: parent
                            text: act.modelData.icon
                            size: 34
                            color: act.modelData.danger ? Theme.danger : Theme.text
                            rotation: act.progress * 360
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: { drainAnim.stop(); fillAnim.start() }
                            onReleased: { fillAnim.stop(); if (act.progress < 1) drainAnim.start() }
                            onCanceled: { fillAnim.stop(); drainAnim.start() }
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: act.modelData.label
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    onOpenChanged: if (!open) for (let i = 0; i < row.children.length; i++) if (row.children[i].progress !== undefined) row.children[i].progress = 0
}
