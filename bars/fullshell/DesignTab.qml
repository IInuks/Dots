import QtQuick

// Theme mode (dark/light/adaptive) + a live transparency slider for the
// bar and Command Center surfaces.
Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var modes: [
        { key: "dark", label: "Dunkel", desc: "Feste dunkle Palette (Aurora).", icon: "moon", pal: Theme.dark },
        { key: "light", label: "Hell", desc: "Feste helle Palette.", icon: "sun", pal: Theme.light },
        { key: "adaptive", label: "Adaptiv", desc: "Farben live aus dem Hintergrundbild.", icon: "droplet", pal: Theme.adaptivePalette || Theme.dark }
    ]

    Column {
        id: col
        width: root.width
        spacing: 22

        Column {
            width: parent.width
            spacing: 8
            Text { text: "Farbschema"; color: Theme.textDim; font.pixelSize: 11 }

            Repeater {
                model: root.modes
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: col.width
                    height: 58
                    radius: Theme.radiusMed
                    color: Theme.mode === modelData.key ? Qt.alpha(Theme.accent, 0.15) : "transparent"
                    border.width: Theme.mode === modelData.key ? 1.5 : 0
                    border.color: Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.animMed } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 34; height: 34; radius: 10
                            color: card.modelData.pal.bg
                            border.width: 1
                            border.color: Theme.surfaceAlt
                            Icon { anchors.centerIn: parent; name: card.modelData.icon; size: 15; tint: card.modelData.pal.accent }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: card.modelData.label; color: Theme.text; font.pixelSize: 14; font.bold: true }
                            Text { text: card.modelData.desc; color: Theme.textDim; font.pixelSize: 11 }
                        }
                    }

                    Icon {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Theme.mode === card.modelData.key
                        name: "checkmark"; size: 15; tint: Theme.accent
                        scale: visible ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.setMode(card.modelData.key)
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 10
            Text { text: "Transparenz"; color: Theme.textDim; font.pixelSize: 11 }

            Row {
                width: parent.width
                spacing: 12
                Slider {
                    width: parent.width - 50
                    anchors.verticalCenter: parent.verticalCenter
                    value: (Settings.barOpacity - 0.35) / 0.65
                    fillColor: Theme.accent2
                    onMoved: v => Settings.setBarOpacity(0.35 + v * 0.65)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    text: Math.round(Settings.barOpacity * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 12
                }
            }

            Text {
                text: "Wirkt live auf Bar und dieses Menü."
                color: Theme.textDim
                font.pixelSize: 10
                font.italic: true
            }
        }
    }
}
