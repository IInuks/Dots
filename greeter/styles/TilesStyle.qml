import QtQuick
import QtQuick.Effects
import Quickshell
import "../components"
import ".."

// A glass top bar (clock, session, power) and the users as tiles; the
// selected tile lifts and glows, the password pill sits below it.
Item {
    id: root

    property var ctl: null
    property bool preview: false

    function focusField() { field.forceActiveFocus(); }

    Backdrop {
        anchors.fill: parent
        blur: field.engaged ? 0.9 : 0.6
        brightness: field.engaged ? -0.18 : -0.1
        saturation: 0.35
        zoom: field.engaged ? 1.03 : 1.0
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // -- top bar ---------------------------------------------------------
    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - 10
        width: parent.width - Theme.edge * 2
        height: 60
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.border
        z: 2
        NumberAnimation on y { running: true; to: 20; duration: 700; easing.type: Easing.OutBack; easing.overshoot: 1.2 }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingL + 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingM
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontXl
                font.weight: Font.Medium
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 22; color: Theme.border }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale().toString(clock.date, "dddd, d. MMMM")
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontM
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingS + 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingM
            SessionPicker {
                anchors.verticalCenter: parent.verticalCenter
                dropDown: true
                alignRight: true
                current: root.ctl.sessionIndex
                onPicked: index => {
                    root.ctl.setSession(index);
                    field.forceActiveFocus();
                }
            }
            PowerBar {
                anchors.verticalCenter: parent.verticalCenter
                ctl: root.ctl
                size: 38
                spacing: Theme.spacingS
                labelBelow: true
            }
        }
    }

    // -- user tiles ----------------------------------------------------------
    Row {
        id: tiles
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: field.engaged ? -70 : -50
        spacing: Theme.spacingXl
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }

        Repeater {
            model: Users.list
            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool picked: index === root.ctl.userIndex
                width: 190
                height: 230
                z: picked ? 1 : 0
                opacity: picked ? 1 : tileMouse.containsMouse ? 0.85 : 0.55
                scale: (picked ? 1.06 : tileMouse.containsMouse ? 0.98 : 0.92) * pop
                property real pop: 0.4
                Behavior on opacity { NumberAnimation { duration: Theme.animMid } }

                SequentialAnimation {
                    running: true
                    PauseAnimation { duration: 250 + tile.index * 110 }
                    NumberAnimation { target: tile; property: "pop"; to: 1; duration: 650; easing.type: Easing.OutBack; easing.overshoot: 2 }
                }
                Behavior on scale { enabled: tile.pop === 1; NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }

                RectangularShadow {
                    anchors.fill: card
                    radius: card.radius
                    blur: 48
                    spread: 2
                    color: Qt.alpha(Theme.accent, tile.picked ? 0.35 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.animMid } }
                }
                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: 26
                    color: Theme.panel
                    border.width: tile.picked ? 2 : 1
                    border.color: tile.picked ? Qt.alpha(Theme.accent, 0.8) : Theme.border
                    Behavior on border.color { ColorAnimation { duration: Theme.animMid } }

                    Item {
                        id: avatar
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 30
                        width: 104
                        height: 104

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.hsla(Theme.hue, WallColors.sat, 0.5, 1) }
                                GradientStop { position: 1; color: Qt.hsla((Theme.hue + 0.08) % 1, WallColors.sat, 0.3, 1) }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: tile.modelData.display.charAt(0).toUpperCase()
                                color: Theme.text
                                font.family: Theme.fontSans
                                font.pixelSize: 46
                                font.weight: Font.Light
                            }
                        }
                        // busy: a dot orbits the avatar
                        Item {
                            anchors.fill: parent
                            anchors.margins: -9
                            visible: tile.picked && Auth.busy
                            RotationAnimation on rotation { running: tile.picked && Auth.busy; from: 0; to: 360; duration: 1100; loops: Animation.Infinite }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 10; height: 10; radius: 5
                                color: Theme.accent
                            }
                        }
                    }
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: avatar.bottom
                        anchors.topMargin: Theme.spacingL
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(implicitWidth, tile.width - 24)
                            elide: Text.ElideRight
                            text: tile.modelData.display
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontL
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "@" + tile.modelData.name
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontS
                        }
                    }
                }
                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.ctl.setUser(tile.index);
                        field.forceActiveFocus();
                    }
                }
            }
        }
    }

    // -- password pill -------------------------------------------------------
    Column {
        id: form
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: tiles.bottom
        anchors.topMargin: Theme.spacingXl + 8
        spacing: Theme.spacingM
        opacity: 0
        transform: Translate { id: rise; y: 30 }
        ParallelAnimation {
            running: true
            SequentialAnimation {
                PauseAnimation { duration: 600 }
                ParallelAnimation {
                    NumberAnimation { target: form; property: "opacity"; to: 1; duration: 500 }
                    NumberAnimation { target: rise; property: "y"; to: 0; duration: 600; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            id: pill
            width: 360
            height: Theme.fieldHeight + 4
            radius: height / 2
            color: Theme.panel
            border.color: field.error !== "" ? Qt.alpha(Theme.danger, 0.7)
                        : field.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
            transform: Translate { id: shift }
            Shake { id: shake; shift: shift }

            PasswordField {
                id: field
                anchors.left: parent.left
                anchors.right: go.left
                anchors.leftMargin: Theme.spacingL + 4
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                ctl: root.ctl
                preview: root.preview
                onRejected: shake.restart()
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text.length === 0
                    text: field.hint + (root.ctl.user ? " for " + root.ctl.user.name : "")
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                }
            }
            Rectangle {
                id: go
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 12
                height: width
                radius: width / 2
                color: field.canSubmit || Auth.busy ? Theme.accent : Theme.panelAlt
                scale: field.canSubmit ? 1 : 0.85
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutBack } }
                Text {
                    anchors.centerIn: parent
                    text: Auth.busy ? "" : ""
                    color: field.canSubmit || Auth.busy ? Theme.accentText : Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    RotationAnimation on rotation { running: Auth.busy; loops: Animation.Infinite; from: 0; to: 360; duration: 900 }
                    onTextChanged: rotation = 0
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: field.submit()
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: field.error !== "" ? field.error : Auth.info
            color: field.error !== "" ? Theme.danger : Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
            opacity: text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }
    }
}
