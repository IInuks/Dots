pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.widgets

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: 54
    color: "transparent"
    WlrLayershell.namespace: "polarlicht-bar"

    IdleInhibitor { window: bar; enabled: Theme.cfg.caffeine }

    SystemClock {
        id: clock
        precision: Theme.cfg.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Einflug-Animation beim Start
    property real intro: 0
    NumberAnimation on intro { from: 0; to: 1; duration: Theme.dur(900); easing.type: Easing.OutQuart }

    // ───────────── links ─────────────
    Island {
        id: left
        x: 10
        y: 8 - (1 - bar.intro) * 60
        implicitWidth: leftRow.implicitWidth + 8

        Row {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            spacing: 4

            BarButton {
                icon: Icons.apps; iconSize: 17
                active: Hub.menu === "launcher"
                onClicked: Hub.toggle("launcher")
            }

            // Tags mit gleitender Markierung
            Item {
                id: tagsBox
                implicitWidth: tagRow.implicitWidth + 8
                implicitHeight: 30

                readonly property int activeIdx: Hub.tags.findIndex(t => t.is_active)
                readonly property Item activeItem: tagRep.count > 0 && activeIdx >= 0 ? tagRep.itemAt(activeIdx) : null

                Rectangle {
                    height: 30; radius: 15
                    color: Theme.accent
                    visible: tagsBox.activeItem !== null
                    x: tagsBox.activeItem ? tagRow.x + tagsBox.activeItem.x : 0
                    width: tagsBox.activeItem ? tagsBox.activeItem.width : 0
                    Behavior on x { SpringAnimation { spring: 5; damping: 0.42; epsilon: 0.3 } }
                    Behavior on width { SpringAnimation { spring: 5; damping: 0.42; epsilon: 0.3 } }
                }

                Row {
                    id: tagRow
                    x: 4
                    Repeater {
                        id: tagRep
                        model: Hub.tags
                        delegate: MouseArea {
                            id: tag
                            required property var modelData
                            required property int index
                            readonly property bool act: modelData.is_active
                            readonly property bool occ: modelData.client_count > 0
                            width: act ? 38 : 22
                            height: 30
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hub.view(modelData.index)
                            Behavior on width { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: tag.act ? 0 : tag.containsMouse ? 12 : tag.occ ? 8 : 6
                                height: width; radius: width / 2
                                color: tag.modelData.is_urgent ? Theme.danger : tag.occ ? Theme.text : "transparent"
                                border.width: tag.occ ? 0 : 1.5
                                border.color: Theme.textDim
                                Behavior on width { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutBack } }
                            }
                            Txt {
                                anchors.centerIn: parent
                                text: tag.modelData.index
                                color: Theme.onAccent
                                font.weight: Font.Bold
                                opacity: tag.act ? 1 : 0
                                scale: tag.act ? 1 : 0.4
                                Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
                                Behavior on scale { NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: w => Hub.dispatch(w.angleDelta.y > 0 ? "viewtoleft_have_client" : "viewtoright_have_client")
                }
            }

            BarButton {
                icon: Icons.window
                label: Hub.layoutSymbol
                active: Hub.menu === "windows"
                onClicked: m => {
                    if (m.button === Qt.RightButton) Hub.dispatch("switch_layout")
                    else Hub.toggle("windows")
                }
            }
        }
    }

    // ───────────── Mitte: „Dynamic Island" ─────────────
    Island {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8 - (1 - bar.intro) * 60
        implicitWidth: centerRow.implicitWidth + 30
        animateWidth: false
        color: Hub.menu === "calendar" ? Theme.surfaceHi : Theme.bg
        Behavior on color { ColorAnimation { duration: Theme.dur(200) } }

        MouseArea {
            id: centerMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hub.toggle("calendar")
        }

        Row {
            id: centerRow
            anchors.centerIn: parent
            spacing: 0

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, Theme.cfg.clockSeconds ? "HH:mm:ss" : "HH:mm")
                    font.pixelSize: 15; font.weight: Font.Bold
                    color: Theme.accent
                }
                Rectangle { width: 4; height: 4; radius: 2; color: Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.locale("de_DE").toString(clock.date, "ddd, d. MMM")
                    color: Theme.textDim
                }
            }

            // Fenstertitel fährt beim Hovern aus
            Item {
                id: titleBox
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool show: centerMa.containsMouse && Hub.title !== ""
                width: show ? Math.min(titleTxt.implicitWidth, 460) + 24 : 0
                height: 20
                clip: true
                Behavior on width { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutCubic } }
                Rectangle { x: 10; width: 1; height: 14; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter }
                Txt {
                    id: titleTxt
                    x: 24
                    width: Math.min(implicitWidth, 460)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hub.title
                    opacity: titleBox.show ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(250) } }
                }
            }

            // laufender Timer
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Hub.timerRunning ? timerPill.width + 10 : 0
                height: 22
                clip: true
                Behavior on width { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutCubic } }
                Rectangle {
                    id: timerPill
                    x: 10
                    height: 22; radius: 11
                    width: timerRow.implicitWidth + 14
                    color: Theme.accentSoft
                    opacity: Hub.timerRunning ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(250) } }
                    Row {
                        id: timerRow
                        anchors.centerIn: parent; spacing: 4
                        Glyph { text: Icons.timer; size: 13; color: Theme.accent }
                        Txt { text: Hub.fmtTimer(Hub.timerLeft); color: Theme.accent; font.pixelSize: 12; font.weight: Font.Bold }
                    }
                }
            }
        }
    }

    // ───────────── rechts ─────────────
    Island {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 8 - (1 - bar.intro) * 60
        implicitWidth: rightRow.implicitWidth + 8

        Row {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            spacing: 2

            BarButton {
                icon: Icons.cpu
                label: Math.round(Hub.cpu * 100) + "%  " + Icons.memory + " " + Math.round(Hub.mem * 100) + "%"
                active: Hub.menu === "system"
                onClicked: Hub.toggle("system")
            }
            BarButton {
                icon: Hub.volIcon(Hub.volume, Hub.muted)
                label: Hub.muted ? "" : Math.round(Hub.volume * 100) + "%"
                active: Hub.menu === "control"
                onClicked: m => {
                    if (m.button === Qt.MiddleButton && Hub.sink?.audio) Hub.sink.audio.muted = !Hub.sink.audio.muted
                    else Hub.toggle("control")
                }
                onWheel: w => Hub.setVolume(Hub.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
            }
            BarButton {
                visible: Theme.cfg.caffeine
                icon: Icons.coffee
                fg: Theme.accent
                onClicked: Theme.cfg.caffeine = false
            }
            BarButton {
                icon: Icons.keyboard
                label: Hub.kbLayout.slice(0, 2).toUpperCase()
                fg: Theme.textDim
                visible: Hub.kbLayout !== ""
                onClicked: Hub.toggle("control")
            }
            BarButton {
                icon: Icons.image
                active: Hub.menu === "walls"
                onClicked: Hub.toggle("walls")
            }
            BarButton {
                icon: Icons.power
                fg: active ? Theme.onAccent : Theme.danger
                active: Hub.menu === "power"
                onClicked: Hub.toggle("power")
            }
        }
    }
}
