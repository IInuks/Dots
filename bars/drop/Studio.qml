import QtQuick

// Labor: Wasserfarbe, Akzent, Deckkraft, Zähigkeit (Animationstempo),
// ein paar Schalter und der Einstieg ins Anordnen der Perlen.
// Alles wirkt sofort und wird gespeichert.
Drip {
    id: root
    popupId: "studio"
    cardWidth: 390

    component SwitchRow: Item {
        id: sr
        property string text: ""
        property string hint: ""
        property bool checked: false
        signal toggled()
        width: parent ? parent.width : 0
        height: 40
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Label { text: sr.text; size: 13 }
            Label { text: sr.hint; size: 11; color: Theme.textFaint; visible: sr.hint.length > 0 }
        }
        Schalter {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: sr.checked
            onToggled: sr.toggled()
        }
    }

    Column {
        width: parent.width
        spacing: 12

        Heading { text: "Wasserfarbe" }
        Flow {
            width: parent.width
            spacing: 6
            Chip {
                text: "Wallpaper"; icon: "image"
                selected: Settings.data.themeMode === "wallpaper"
                onClicked: Settings.data.themeMode = "wallpaper"
            }
            Repeater {
                model: Theme.presetNames
                Chip {
                    required property string modelData
                    text: Theme.presetLabels[modelData]
                    swatch: Theme.presets[modelData].accent
                    selected: Settings.data.themeMode === modelData
                    onClicked: Settings.data.themeMode = modelData
                }
            }
        }

        // Akzent aus den Wallpaper-Kandidaten
        Column {
            width: parent.width
            spacing: 8
            visible: Settings.data.themeMode === "wallpaper"
            Label {
                text: Wall.ready ? "Akzent aus dem Wallpaper" : "Wallpaper wird noch gelesen …"
                size: 12; color: Theme.textDim
            }
            Row {
                spacing: 8
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: Settings.data.accentPick < 0 ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.text, 0.06)
                    border.width: Settings.data.accentPick < 0 ? 2 : 0
                    border.color: Theme.accent
                    Label { anchors.centerIn: parent; text: "A"; bold: true; size: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.accentPick = -1 }
                }
                Repeater {
                    model: Theme.candidates
                    Droplet {
                        required property string modelData
                        required property int index
                        width: 23; height: 31
                        fill: modelData
                        rim: Settings.data.accentPick === index ? Theme.text : "transparent"
                        scale: dma.containsMouse ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                        MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.accentPick = index }
                    }
                }
            }
        }

        Heading { text: "Zähigkeit" }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [
                    { l: "Starr", v: 0 },
                    { l: "Wasser", v: 0.6 },
                    { l: "Normal", v: 1.0 },
                    { l: "Honig", v: 1.6 }
                ]
                Chip {
                    required property var modelData
                    text: modelData.l
                    selected: Math.abs(Settings.data.animSpeed - modelData.v) < 0.01
                    onClicked: Settings.data.animSpeed = modelData.v
                }
            }
        }

        Heading { text: "Deckkraft" }
        Row {
            width: parent.width
            spacing: 12
            Pegel {
                width: parent.width - 52
                anchors.verticalCenter: parent.verticalCenter
                value: (Settings.data.opacity - 0.5) / 0.5
                onMoved: v => Settings.data.opacity = Math.round((0.5 + v * 0.5) * 100) / 100
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Settings.data.opacity * 100) + " %"
                size: 12; color: Theme.textDim; font.family: Theme.mono
            }
        }

        Heading { text: "Perlen" }
        Item {
            width: parent.width
            height: 34
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - arrangeChip.width - 10
                text: Arrange.hasSaved ? "Eigene Anordnung" : "Standard-Anordnung"
                size: 12; color: Theme.textDim
            }
            Chip {
                id: arrangeChip
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Anordnen"; icon: "drag"
                onClicked: Arrange.begin()
            }
        }

        Column {
            width: parent.width
            SwitchRow {
                text: "Wasserfilm"; hint: "durchgehender Film am oberen Rand"
                checked: Settings.data.film
                onToggled: Settings.data.film = !Settings.data.film
            }
            SwitchRow {
                text: "Wellenringe"; hint: "bei jedem Klick auf eine Perle"
                checked: Settings.data.ripples
                onToggled: Settings.data.ripples = !Settings.data.ripples
            }
            SwitchRow {
                text: "Sekunden"
                checked: Settings.data.showSeconds
                onToggled: Settings.data.showSeconds = !Settings.data.showSeconds
            }
            SwitchRow {
                text: "Abdunkeln"; hint: "Hintergrund hinter den Menüs"
                checked: Settings.data.dim
                onToggled: Settings.data.dim = !Settings.data.dim
            }
        }
    }
}
