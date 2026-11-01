import QtQuick
import Quickshell
import "../"
import "../Bar"

// Grid picker over Config.wallpaperDir (~/Pictures/Walpapers), 5 columns,
// active wallpaper ring-marked. Click applies via Wallpaper.apply() (awww
// fade transition + wal + matugen regen, see Wallpaper.qml). Random button
// + optional slideshow timer per the original brief's "Optional" line.
PanelSheet {
    id: root
    open: PanelState.openPanel === "wallpapers"
    horizontalAlign: "stretch"
    sheetHeight: Math.round((Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 900) * 0.6)
    sideMargin: 24

    readonly property int columns: 5
    readonly property int cellSpacing: 10

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Item {
            // Item, not Row -- a Row rejects left/right/horizontalCenter/
            // fill/centerIn anchors on its own direct children, and the
            // controls cluster below needs anchors.right (confirmed via
            // `qs ... -n` + `qs ... log` on this system).
            width: parent.width
            height: 30

            Text {
                text: "Wallpaper"
                color: Theme.text
                font.family: Theme.uiFontFamily
                font.pixelSize: 14
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: Theme.surfaceVariant
                    Icon { anchors.centerIn: parent; glyph: "shuffle"; fallback: "?"; size: 16 }
                    MouseArea { anchors.fill: parent; onClicked: Wallpaper.applyRandom() }
                }

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: Config.slideshowEnabled ? Theme.accent : Theme.surfaceVariant
                    Icon {
                        anchors.centerIn: parent
                        glyph: "timer"
                        fallback: "T"
                        size: 16
                        tint: Config.slideshowEnabled ? Theme.accentInk : Theme.text
                    }
                    MouseArea { anchors.fill: parent; onClicked: Config.setSlideshowEnabled(!Config.slideshowEnabled) }
                }

                Text {
                    visible: Config.slideshowEnabled
                    text: "alle " + Config.slideshowIntervalMin + " min"
                    color: Theme.textMuted
                    font.family: Theme.uiFontFamily
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        GridView {
            id: grid
            width: parent.width
            height: parent.height - 42
            clip: true
            cellWidth: (width - root.cellSpacing * (root.columns - 1)) / root.columns + root.cellSpacing
            cellHeight: cellWidth * 0.62
            model: Wallpaper.files

            delegate: Item {
                required property string modelData
                width: grid.cellWidth - root.cellSpacing
                height: grid.cellHeight - root.cellSpacing

                readonly property bool isActive: modelData === Wallpaper.current

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.surfaceVariant
                    border.width: isActive ? 3 : 0
                    border.color: Theme.accent
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: isActive ? 3 : 0
                        source: "file://" + modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 240
                        sourceSize.height: 150
                    }

                    Rectangle {
                        visible: isActive
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 20; height: 20; radius: 10
                        color: Theme.accent
                        Icon { anchors.centerIn: parent; glyph: "check"; fallback: "✓"; size: 12; tint: Theme.accentInk }
                    }

                    Rectangle {
                        visible: Wallpaper.applying && Wallpaper.current === modelData
                        anchors.fill: parent
                        color: "#00000066"
                        Text { anchors.centerIn: parent; text: "..."; color: "white"; font.pixelSize: 18 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Wallpaper.apply(modelData)
                }
            }
        }
    }
}
