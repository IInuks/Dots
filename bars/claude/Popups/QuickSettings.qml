import QtQuick
import ".."

PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.quickSettingsWidth
    panelHeight: Metrics.quickSettingsHeight

    readonly property var modes: [
        { key: "dark", label: "Dunkel", glyph: "moon" },
        { key: "light", label: "Hell", glyph: "sun" },
        { key: "adaptive", label: "Adaptiv", glyph: "drop" }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 18

        Column {
            width: parent.width
            spacing: 8
            Text { text: "Farbschema"; color: Chroma.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.modes
                    delegate: Rectangle {
                        id: modeBtn
                        required property var modelData
                        width: (root.panelWidth - 32 - 16) / 3
                        height: 62
                        radius: Chroma.rSmall
                        readonly property bool active: Config.mode === modeBtn.modelData.key
                        color: modeBtn.active ? Qt.alpha(Chroma.accent, 0.2) : (hoverArea.containsMouse ? Chroma.panelRaised : "transparent")
                        border.width: modeBtn.active ? 1 : 0
                        border.color: Chroma.accent
                        Behavior on color { ColorAnimation { duration: Chroma.tFast } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: modeBtn.modelData.glyph
                                width: 16; height: 16
                                tint: modeBtn.active ? Chroma.accent : Chroma.text
                                fill: modeBtn.modelData.glyph !== "sun"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modeBtn.modelData.label
                                color: modeBtn.active ? Chroma.text : Chroma.textFaint
                                font.family: Metrics.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setMode(modeBtn.modelData.key)
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8
            Text { text: "Leisten-Deckkraft"; color: Chroma.textFaint; font.family: Metrics.fontFamily; font.pixelSize: 11 }
            Row {
                width: parent.width
                spacing: 10
                Slider {
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    value: Config.barAlpha
                    onMoved: v => Config.setBarAlpha(v)
                }
                Text {
                    width: 30
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Config.barAlpha * 100) + "%"
                    color: Chroma.text
                    font.family: Metrics.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        Row {
            width: parent.width
            Text {
                text: "Nicht stören"
                color: Chroma.text
                font.family: Metrics.fontFamily
                font.pixelSize: 12
                width: parent.width - 40
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 34; height: 18; radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: Config.dnd ? Chroma.accent : Chroma.panelRaised
                Behavior on color { ColorAnimation { duration: Chroma.tMed } }

                Rectangle {
                    width: 12; height: 12; radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: Config.dnd ? parent.width - width - 3 : 3
                    color: Chroma.text
                    Behavior on x { SpringAnimation { spring: 3.5; damping: 0.45 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.setDnd(!Config.dnd)
                }
            }
        }
    }
}
