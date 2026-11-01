import QtQuick
import "../../"

// WLAN password panel (menus prompt 1.2's "Passwort-Panel" + "Signature-
// Detail"): a real (invisible, echoMode NoEcho) TextInput drives a fake
// display -- one popping glyph per typed character, cycling through
// ⬢ ◆ ▲ ● ■ ⬟ ★ and rotating primary/tertiary/secondary, plus a blinking
// 1x12px cursor after the last glyph. Height animates open/closed (180ms)
// since this only exists while a secured, unconnected network is selected.
Item {
    id: root

    property bool open: false
    signal cancelled
    signal connectRequested(string password)

    readonly property var _glyphs: ["⬢", "◆", "▲", "●", "■", "⬟", "★"]
    readonly property var _glyphColors: [Colors.primary, Colors.tertiary, Colors.secondary]

    implicitWidth: parent ? parent.width : 296
    implicitHeight: root.open ? panel.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }

    // Real focus request is plumbed up to BarShell (memory:
    // feedback_wlr_layershell_keyboard_focus_none /
    // feedback_mango_ondemand_focus_requires_fresh_surface -- see README
    // "Bekannte Risiken", this is unverified against mango's actual
    // OnDemand-refresh behavior on a long-lived reused surface).
    onOpenChanged: {
        if (root.open) {
            hiddenInput.text = "";
            hiddenInput.forceActiveFocus();
        }
    }

    Column {
        id: panel
        width: parent.width
        spacing: 8
        topPadding: 8
        bottomPadding: 8
        leftPadding: 8
        rightPadding: 8

        Rectangle {
            width: panel.width
            height: panelBody.implicitHeight + 16
            radius: 4
            color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.6)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.45)

            Column {
                id: panelBody
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 6

                Row {
                    spacing: 6
                    Text {
                        font.family: Style.iconFont
                        font.pixelSize: 11
                        color: Colors.primary
                        text: "\u{F0306}"
                    }
                    Text {
                        font.family: Style.textFont
                        font.pixelSize: 11
                        color: Colors.primary
                        text: "Password"
                    }
                }

                Rectangle {
                    id: field
                    width: parent.width
                    height: 24
                    radius: 3
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.8)
                    border.width: 1
                    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)

                    TextInput {
                        id: hiddenInput
                        anchors.fill: parent
                        echoMode: TextInput.NoEcho
                        color: "transparent"
                        selectByMouse: true
                        onAccepted: root.connectRequested(hiddenInput.text)
                        Keys.onEscapePressed: root.cancelled()
                    }

                    Text {
                        visible: hiddenInput.text.length === 0
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Style.textFont
                        font.pixelSize: 11
                        color: Qt.rgba(Colors.surfaceText.r, Colors.surfaceText.g, Colors.surfaceText.b, 0.35)
                        text: "Password"
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: hiddenInput.text.length

                            Text {
                                id: glyph
                                required property int index
                                font.pixelSize: 11
                                color: root._glyphColors[index % root._glyphColors.length]
                                text: root._glyphs[index % root._glyphs.length]
                                transformOrigin: Item.Center

                                // Pop-in: 0.4 -> 1.15 (90ms) -> 1.0 (110ms) each
                                // time this glyph slot first appears.
                                scale: 0.4
                                Component.onCompleted: popAnim.start()
                                SequentialAnimation {
                                    id: popAnim
                                    NumberAnimation { target: glyph; property: "scale"; to: 1.15; duration: 90; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: glyph; property: "scale"; to: 1.0; duration: 110; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        Rectangle {
                            id: cursor
                            width: 1
                            height: 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.primary
                            visible: hiddenInput.activeFocus

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: cursor.visible
                                NumberAnimation { to: 0; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }

                Row {
                    spacing: 8
                    anchors.right: parent.right

                    Rectangle {
                        width: cancelLabel.implicitWidth + 16
                        height: 20
                        radius: 3
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.4)

                        Text {
                            id: cancelLabel
                            anchors.centerIn: parent
                            font.family: Style.textFont
                            font.pixelSize: 10
                            color: Colors.outline
                            text: "CANCEL"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.cancelled()
                        }
                    }

                    Rectangle {
                        width: connectLabel.implicitWidth + 16
                        height: 20
                        radius: 3
                        color: Colors.primary

                        Text {
                            id: connectLabel
                            anchors.centerIn: parent
                            font.family: Style.textFont
                            font.pixelSize: 10
                            color: Colors.surface
                            text: "CONNECT"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.connectRequested(hiddenInput.text)
                        }
                    }
                }
            }
        }
    }
}
