import QtQuick
import QtQuick.Effects
import Quickshell
import "../components"
import ".."

// A frosted panel on the left with everything in it; the rest of the screen
// is the sharp wallpaper, slowly drifting (Ken Burns).
Item {
    id: root

    property var ctl: null
    property bool preview: false

    readonly property real panelWidth: Math.max(400, Math.min(520, width * 0.32))

    function focusField() { field.forceActiveFocus(); }

    Backdrop {
        id: wall
        anchors.fill: parent
        blur: 0
        brightness: field.engaged ? -0.18 : -0.06
        saturation: 0.7
        zoomDuration: 0
        SequentialAnimation on zoom {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.08; duration: 30000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0; duration: 30000; easing.type: Easing.InOutSine }
        }
    }

    // big date on the wallpaper side, very faint
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.edge
        text: Qt.locale().toString(clock.date, "dddd")
        color: Qt.alpha(Theme.text, 0.18)
        font.family: Theme.fontSans
        font.pixelSize: 96
        font.weight: Font.Thin
        opacity: panel.x > -root.panelWidth + 1 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1200 } }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // -- the panel --------------------------------------------------------
    Item {
        id: panel
        width: root.panelWidth
        height: parent.height
        x: -width
        clip: true

        NumberAnimation on x {
            running: true
            to: 0
            duration: 750
            easing.type: Easing.OutQuart
        }

        // frosted glass: the same wallpaper, blurred, lined up with the one behind
        MultiEffect {
            x: -panel.x
            width: root.width
            height: root.height
            source: wall
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            brightness: -0.1
            saturation: 0.3
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.hsla(Theme.hue, 0.2, 0.07, 0.72 + Theme.dim * 0.3)
        }
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.alpha(Theme.accent, 0.5) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // content columns fade/slide in one after another
        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 48

            // -- top: clock --------------------------------------------
            Column {
                id: top
                Stagger on opacity { index: 0 }
                spacing: 0
                Text {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 84
                    font.weight: Font.Light
                }
                Text {
                    text: Qt.locale().toString(clock.date, "d. MMMM yyyy")
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    font.letterSpacing: 1
                }
            }

            // -- middle: user + password -------------------------------
            Column {
                id: form
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 20
                spacing: Theme.spacingM
                Stagger on opacity { index: 1 }

                Text {
                    text: "Welcome back,"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: Qt.alpha(Theme.accent, 0.18)
                        border.color: Qt.alpha(Theme.accent, 0.5)
                        Text {
                            anchors.centerIn: parent
                            text: root.ctl.user ? root.ctl.user.display.charAt(0).toUpperCase() : "?"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXl
                            font.weight: Font.Medium
                        }
                    }
                    Text {
                        id: name
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44 - switcher.width - Theme.spacingM * 2
                        elide: Text.ElideRight
                        text: root.ctl.user ? root.ctl.user.display : "No users"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                        font.weight: Font.Medium
                    }
                    Row {
                        id: switcher
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.ctl.multiUser
                        spacing: Theme.spacingXs
                        IconButton { size: 30; glyph: ""; onClicked: root.ctl.cycleUser(-1) }
                        IconButton { size: 30; glyph: ""; onClicked: root.ctl.cycleUser(1) }
                    }
                }

                Item { width: 1; height: Theme.spacingS }

                // field with an underline that fills with the accent while typing
                Rectangle {
                    id: box
                    width: parent.width
                    height: 52
                    radius: Theme.radiusSmall
                    color: Theme.panelAlt
                    border.color: field.error !== "" ? Qt.alpha(Theme.danger, 0.7) : Theme.border
                    transform: Translate { id: shift }
                    Shake { id: shake; shift: shift }

                    Text {
                        id: lock
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        text: Auth.busy ? "󰔟" : ""
                        color: field.activeFocus ? Theme.accent : Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontL
                        RotationAnimation on rotation { running: Auth.busy; loops: Animation.Infinite; from: 0; to: 360; duration: 1200 }
                        onTextChanged: rotation = 0
                    }
                    PasswordField {
                        id: field
                        anchors.left: lock.right
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        ctl: root.ctl
                        preview: root.preview
                        onRejected: shake.restart()
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text.length === 0
                            text: field.hint
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 2
                        radius: 1
                        width: field.activeFocus || root.preview ? parent.width - Theme.radiusSmall * 2 : 0
                        color: field.error !== "" ? Theme.danger : Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                    }
                }

                // sign-in button
                Rectangle {
                    width: parent.width
                    height: 46
                    radius: Theme.radiusSmall
                    color: field.canSubmit || Auth.busy ? Theme.accent : Theme.panelAlt
                    scale: signMouse.pressed ? 0.98 : 1
                    Behavior on color { ColorAnimation { duration: Theme.animMid } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS
                        Text {
                            text: Auth.busy ? "Signing in" : "Sign in"
                            color: field.canSubmit || Auth.busy ? Theme.accentText : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                            font.weight: Font.Medium
                        }
                        Text {
                            text: ""
                            color: field.canSubmit || Auth.busy ? Theme.accentText : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                            // nudges right on hover
                            transform: Translate { x: signMouse.containsMouse ? 4 : 0; Behavior on x { NumberAnimation { duration: Theme.animFast } } }
                        }
                    }
                    MouseArea {
                        id: signMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: field.submit()
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: field.error !== "" ? field.error : Auth.info
                    color: field.error !== "" ? Theme.danger : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                    opacity: text !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                }
            }

            // -- bottom: sessions + power ------------------------------
            Column {
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: Theme.spacingL
                Stagger on opacity { index: 2 }

                Text {
                    text: "SESSION"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                    font.letterSpacing: 2
                }
                Column {
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: Sessions.list
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool picked: index === root.ctl.sessionIndex
                            width: parent.width
                            height: 36
                            radius: Theme.radiusSmall
                            color: picked ? Qt.alpha(Theme.accent, 0.14) : rowMouse.containsMouse ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8; height: 8; radius: 4
                                color: row.picked ? Theme.accent : "transparent"
                                border.color: row.picked ? Theme.accent : Theme.textFaint
                                scale: row.picked ? 1.25 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutBack } }
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM + 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.name
                                color: row.picked ? Theme.text : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontM
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.ctl.setSession(row.index);
                                    field.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
                PowerBar {
                    ctl: root.ctl
                    size: 40
                }
            }
        }
    }

    // fades a section in after the panel has slid out
    component Stagger: NumberAnimation {
        property int index: 0
        from: 0
        to: 1
        duration: 500 + index * 180
        easing.type: Easing.InQuad
    }
}
