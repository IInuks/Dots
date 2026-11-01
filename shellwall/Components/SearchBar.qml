import QtQuick

// Angelehnt an quickdots/bars/ricev2/Bar/launcher/FilterBar.qml: dieselbe
// Pill-Leiste (Icon + Suchfeld mit blinkendem Caret + Hinweistext), aber
// ohne die dortigen Filter-Buttons (All/Apps/Games/Steam) -- fuer
// Wallpaper gibt es keine vergleichbaren Kategorien. Das Suchfeld ist wie
// dort handgezeichnet (Text + Caret statt echtem TextInput), weil Links/
// Rechts immer durch die Slices blaettern soll und jede sonstige Taste im
// Suchtext landet -- die eigentliche Tastaturlogik sitzt im Overlay.
Item {
    id: root

    required property var config
    required property string searchText

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        height: row.implicitHeight + 14
        width: row.implicitWidth + 30
        radius: height / 2
        color: Qt.rgba(root.config.surfaceContainer.r, root.config.surfaceContainer.g, root.config.surfaceContainer.b, 0.85)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 16

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0349}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: root.config.tertiary
                }

                Item {
                    width: 240
                    height: searchLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: placeholder
                        visible: root.searchText.length === 0
                        text: "Wallpaper suchen"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.4)
                    }

                    Row {
                        spacing: 1
                        Text {
                            id: searchLabel
                            text: root.searchText
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: root.config.textColor
                        }
                        Rectangle {
                            width: 1
                            height: searchLabel.font.pixelSize + 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.config.primary
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.visible
                                NumberAnimation { to: 0; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "← → auswählen · Enter setzen · Esc schließen"
                font.pixelSize: 11
                color: Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.5)
            }
        }
    }
}
