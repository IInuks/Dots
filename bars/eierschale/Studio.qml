import QtQuick
import QtQuick.Layouts

// "Werkbank": alles, was sich anpassen lässt. Jede Änderung wirkt sofort
// und wird gespeichert (Settings.qml).
PopupCard {
    id: root
    popupId: "studio"
    width: 440

    component Section: Label { size: 11; bold: true; color: Theme.textFaint; topPadding: 4 }
    component SwitchRow: RowLayout {
        property string label
        property bool on
        signal toggled(bool v)
        width: parent.width
        Label { Layout.fillWidth: true; text: parent.label; size: 13 }
        Schalter { on: parent.on; onToggled: v => parent.toggled(v) }
    }

    Column {
        width: parent.width
        spacing: 12

        Row {
            spacing: 10
            Icon { name: "tune"; size: 22; color: Theme.accent }
            Label { text: "Werkbank"; size: 19; bold: true }
        }

        // ------------------------------------------ Farben
        Section { text: "FARBQUELLE" }
        Row {
            width: parent.width
            spacing: 8

            // Wallpaper
            Rectangle {
                id: wallChip
                readonly property bool on: Settings.data.themeMode === "wallpaper"
                width: 130; height: 86; radius: 14
                color: Theme.surface2
                border.width: on ? 2 : 0; border.color: Theme.accent
                clip: true
                Image {
                    anchors.fill: parent; anchors.margins: 2
                    source: Wall.path !== "" ? "file://" + Wall.path : ""
                    sourceSize.width: 260
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.85
                }
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.margins: 2
                    height: 26; radius: 12
                    color: Theme.alpha(Theme.base, 0.8)
                    Label { anchors.centerIn: parent; text: "Wallpaper"; size: 11.5; bold: wallChip.on }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.themeMode = "wallpaper" }
            }

            Grid {
                columns: 2; spacing: 6
                Repeater {
                    model: Theme.presetNames
                    Rectangle {
                        id: chip
                        required property string modelData
                        readonly property var p: Theme.presets[modelData]
                        readonly property bool on: Settings.data.themeMode === modelData
                        width: (root.width - root.padding * 2 - 138 - 6) / 2; height: 40; radius: 12
                        color: p.base
                        border.width: on ? 2 : 1; border.color: on ? p.accent : Theme.line
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Rectangle { width: 12; height: 12; radius: 6; color: chip.p.accent; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle { width: 12; height: 12; radius: 6; color: chip.p.accent2; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: " " + chip.modelData.charAt(0).toUpperCase() + chip.modelData.slice(1); size: 11.5; color: chip.p.text }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.themeMode = chip.modelData }
                    }
                }
            }
        }

        // Akzent aus dem Wallpaper
        Column {
            width: parent.width
            spacing: 8
            visible: Settings.data.themeMode === "wallpaper"
            Section { text: "AKZENT AUS DEM WALLPAPER" }
            Row {
                spacing: 8
                Rectangle {
                    width: 44; height: 28; radius: 14
                    color: Settings.data.accentPick < 0 ? Theme.accent : Theme.surface2
                    Label { anchors.centerIn: parent; text: "Auto"; size: 11; bold: true; color: Settings.data.accentPick < 0 ? Theme.onAccent : Theme.text }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.accentPick = -1 }
                }
                Repeater {
                    model: Theme.candidates
                    Rectangle {
                        required property color modelData
                        required property int index
                        readonly property bool on: Settings.data.accentPick === index
                        width: 28; height: 28; radius: 14
                        color: modelData
                        border.width: on ? 3 : 0; border.color: Theme.text
                        scale: cma.containsMouse ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                        MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.accentPick = parent.index }
                    }
                }
            }
        }

        // ------------------------------------------ Leiste
        Section { text: "LEISTE" }
        SwitchRow { label: "Schwebend"; on: Settings.data.floating; onToggled: v => Settings.data.floating = v }
        RowLayout {
            width: parent.width; spacing: 12
            Label { text: "Rundung"; size: 13; Layout.preferredWidth: 90 }
            Schieber { Layout.fillWidth: true; value: Settings.data.radius / 24; onMoved: v => Settings.data.radius = Math.round(v * 24) }
            Label { text: Settings.data.radius; size: 12; font.family: Theme.mono; color: Theme.textDim; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            width: parent.width; spacing: 12
            Label { text: "Deckkraft"; size: 13; Layout.preferredWidth: 90 }
            Schieber { Layout.fillWidth: true; value: (Settings.data.opacity - 0.4) / 0.6; onMoved: v => Settings.data.opacity = Math.round((0.4 + v * 0.6) * 100) / 100 }
            Label { text: Math.round(Settings.data.opacity * 100); size: 12; font.family: Theme.mono; color: Theme.textDim; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
        }
        SwitchRow { label: "Sekunden anzeigen"; on: Settings.data.showSeconds; onToggled: v => Settings.data.showSeconds = v }

        // ------------------------------------------ Bewegung
        Section { text: "BEWEGUNG" }
        Row {
            spacing: 6
            Repeater {
                model: [["Aus", 0], ["Flott", 0.6], ["Normal", 1], ["Gemütlich", 1.6]]
                Rectangle {
                    required property var modelData
                    readonly property bool on: Math.abs(Settings.data.animSpeed - modelData[1]) < 0.01
                    width: (root.width - root.padding * 2 - 18) / 4; height: 34; radius: 17
                    color: on ? Theme.accent : Theme.surface2
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }
                    Label { anchors.centerIn: parent; text: parent.modelData[0]; size: 12; bold: parent.on; color: parent.on ? Theme.onAccent : Theme.text }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.data.animSpeed = parent.modelData[1] }
                }
            }
        }
        SwitchRow { label: "Ei wackelt ab und zu"; on: Settings.data.eggWobble; onToggled: v => Settings.data.eggWobble = v }
        SwitchRow { label: "Hintergrund abdunkeln"; on: Settings.data.dim; onToggled: v => Settings.data.dim = v }
    }
}
