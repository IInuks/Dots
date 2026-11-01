import QtQuick
import QtQuick.Layouts

// "Schaltzentrale": Begrüßung, Lautstärke, Mikrofon, Ausgabegerät und ein
// paar Schnellschalter.
PopupCard {
    id: root
    popupId: "control"
    width: 380

    readonly property string greeting: {
        const h = new Date().getHours();
        return h < 5 ? "Gute Nacht" : h < 11 ? "Guten Morgen" : h < 14 ? "Mahlzeit" : h < 18 ? "Guten Tag" : h < 22 ? "Guten Abend" : "Gute Nacht";
    }

    component SliderRow: RowLayout {
        property string icon
        property real value
        property bool off
        property color tint: Theme.accent
        signal toggle()
        signal moved(real v)
        width: parent.width
        spacing: 12
        Knopf {
            Layout.preferredWidth: 38; Layout.preferredHeight: 38
            color: parent.off ? Theme.surface3 : Theme.alpha(parent.tint, 0.2)
            onClicked: parent.toggle()
            Icon { anchors.centerIn: parent; name: parent.parent.icon; size: 18; color: parent.parent.off ? Theme.textFaint : parent.parent.tint }
        }
        Schieber {
            Layout.fillWidth: true
            value: parent.value
            tint: parent.off ? Theme.textFaint : parent.tint
            onMoved: v => parent.moved(v)
        }
        Label {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: Math.round(parent.value * 100)
            font.family: Theme.mono; size: 12; color: Theme.textDim
        }
    }

    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        property bool on
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 16
        color: on ? Theme.accent : Theme.surface2
        Behavior on color { ColorAnimation { duration: Theme.tMed } }
        scale: tma.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
        Column {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Icon { name: tile.icon; size: 18; color: tile.on ? Theme.onAccent : Theme.text }
            Label { text: tile.label; size: 12; bold: true; color: tile.on ? Theme.onAccent : Theme.text }
        }
        MouseArea { id: tma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tile.clicked() }
    }

    Column {
        width: parent.width
        spacing: 16

        Row {
            spacing: 12
            EggShape {
                width: 30; height: 38
                fill: Theme.accent; band: Theme.accent2
                rotation: root.shown ? 0 : -30
                Behavior on rotation { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutElastic } }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: root.greeting + "!"; size: 19; bold: true }
                Label { text: new Date().toLocaleDateString(Qt.locale("de_DE"), "dddd, d. MMMM"); size: 12; color: Theme.textDim }
            }
        }

        SliderRow {
            icon: Audio.icon()
            value: Audio.volume
            off: Audio.muted
            onToggle: Audio.toggleMute()
            onMoved: v => Audio.setVolume(v)
        }
        SliderRow {
            icon: Audio.micMuted ? "micOff" : "mic"
            value: Audio.micVolume
            off: Audio.micMuted
            tint: Theme.accent2
            onToggle: Audio.toggleMic()
            onMoved: v => Audio.setMic(v)
        }

        // Ausgabegeräte
        Column {
            width: parent.width
            spacing: 4
            visible: Audio.sinks.length > 1
            Label { text: "Ausgabe"; size: 11; bold: true; color: Theme.textFaint }
            Repeater {
                model: Audio.sinks
                delegate: Knopf {
                    required property var modelData
                    readonly property bool cur: Audio.sink && modelData.id === Audio.sink.id
                    width: parent.width; height: 34
                    radius: 10
                    active: cur
                    onClicked: Audio.setSink(modelData)
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Icon { name: /head/i.test(parent.parent.modelData.description) ? "headphones" : "speaker"; size: 15; color: parent.parent.cur ? Theme.accent : Theme.textDim }
                        Label {
                            width: root.width - 90
                            text: parent.parent.modelData.description || parent.parent.modelData.name
                            size: 12.5; color: parent.parent.cur ? Theme.text : Theme.textDim
                        }
                    }
                }
            }
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 8; rowSpacing: 8
            Tile {
                icon: "sparkle"; label: "Animationen"
                on: Settings.data.animSpeed > 0
                onClicked: Settings.data.animSpeed = Settings.data.animSpeed > 0 ? 0 : 1
            }
            Tile {
                icon: "window"; label: "Schwebende Leiste"
                on: Settings.data.floating
                onClicked: Settings.data.floating = !Settings.data.floating
            }
            Tile {
                icon: "image"; label: "Wallpaper-Farben"
                on: Settings.data.themeMode === "wallpaper"
                onClicked: Settings.data.themeMode = Settings.data.themeMode === "wallpaper" ? "schoko" : "wallpaper"
            }
            Tile {
                icon: "clock"; label: "Sekunden"
                on: Settings.data.showSeconds
                onClicked: Settings.data.showSeconds = !Settings.data.showSeconds
            }
        }

        // aktuelle Palette
        Row {
            spacing: 6
            Repeater {
                model: [Theme.base, Theme.surface2, Theme.accent, Theme.accent2, Theme.text]
                Rectangle {
                    required property color modelData
                    required property int index
                    width: 22; height: 22; radius: 11
                    color: modelData
                    border.width: 1; border.color: Theme.line
                    scale: root.shown ? 1 : 0
                    Behavior on scale { SequentialAnimation { PauseAnimation { duration: Theme.ms(index * 50) } NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } } }
                }
            }
            Label { text: "  Werkbank für mehr"; size: 11.5; color: Theme.textFaint; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.open("studio", root.screenName, Ui.anchorX) }
            }
        }
    }
}
