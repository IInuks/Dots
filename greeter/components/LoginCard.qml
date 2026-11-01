import QtQuick
import ".."

// Avatar, user name (with switch arrows) and the password field.
Item {
    id: root

    property var ctl: null
    property bool preview: false
    // true while the user is typing -- background blurs, clock moves up
    readonly property bool engaged: field.engaged

    implicitWidth: Theme.cardWidth
    implicitHeight: column.implicitHeight

    function focusField() { field.forceActiveFocus(); }

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacingL

        // -- avatar ----------------------------------------------------
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.avatarSize + 10
            height: width

            // slowly turning accent ring while authenticating
            Rectangle {
                id: ring
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Auth.busy ? Theme.accent : Qt.alpha(Theme.accent, 0.45)
                Behavior on border.color { ColorAnimation { duration: Theme.animMid } }

                SequentialAnimation on scale {
                    running: Auth.busy
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 1.06; duration: 420; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: Theme.avatarSize
                height: width
                radius: width / 2
                color: Theme.panel
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: root.ctl?.user ? root.ctl.user.display.charAt(0).toUpperCase() : ""
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.avatarSize * 0.42
                    font.weight: Font.Medium
                }
            }
        }

        // -- user name -------------------------------------------------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingM

            Arrow {
                glyph: ""
                visible: root.ctl?.multiUser ?? false
                onClicked: root.ctl.cycleUser(-1)
            }

            Text {
                id: nameLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.ctl?.user ? root.ctl.user.display : "No users"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontXl
                font.weight: Font.Medium
            }

            Arrow {
                glyph: ""
                visible: root.ctl?.multiUser ?? false
                onClicked: root.ctl.cycleUser(1)
            }
        }

        // -- password field --------------------------------------------
        Rectangle {
            id: box
            width: parent.width
            height: Theme.fieldHeight
            radius: height / 2
            color: Theme.panel
            border.width: 1
            border.color: field.error !== "" ? Qt.alpha(Theme.danger, 0.7)
                        : field.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            transform: Translate { id: shakeShift }

            Shake { id: shake; shift: shakeShift }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingL + 2
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: field.activeFocus ? Theme.accent : Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontM
            }

            PasswordField {
                id: field
                anchors.left: parent.left
                anchors.right: go.left
                anchors.leftMargin: Theme.spacingL * 2 + 6
                anchors.rightMargin: Theme.spacingS
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

            // submit button / spinner
            Rectangle {
                id: go
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 10
                height: width
                radius: width / 2
                color: field.text.length > 0 || Auth.busy ? Theme.accent : Theme.panelAlt
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: Auth.busy ? "" : ""
                    color: field.text.length > 0 || Auth.busy ? Theme.accentText : Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM

                    RotationAnimation on rotation {
                        running: Auth.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                    onTextChanged: rotation = 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: field.submit()
                }
            }
        }

        // -- error / PAM info line -------------------------------------
        Text {
            width: parent.width
            text: field.error
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
            opacity: text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: Auth.info !== "" && field.error === ""
            text: Auth.info
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
        }
    }

    component Arrow: Text {
        id: arrow
        signal clicked()
        property string glyph
        anchors.verticalCenter: parent.verticalCenter
        text: glyph
        color: arrowMouse.containsMouse ? Theme.accent : Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontM
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.clicked()
        }
    }
}
