pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs
import qs.widgets

MenuCard {
    id: root
    name: "walls"
    originY: 1
    width: 940
    height: 620

    onOpenChanged: if (open) Hub.refreshWalls()

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        Item {
            width: parent.width; height: 40
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: "Hintergründe"; font.pixelSize: 18; font.weight: Font.Bold }
                Txt { text: Hub.wallpapers.length + " Bilder · die Farben der Shell folgen dem Bild"; font.pixelSize: 11; color: Theme.textDim }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -6
                    Repeater {
                        model: Theme.swatches
                        Rectangle {
                            required property color modelData
                            width: 22; height: 22; radius: 11
                            color: modelData; border.width: 2; border.color: Theme.bg
                        }
                    }
                }
                BarButton {
                    icon: Icons.dice; label: "Zufall"
                    color: Theme.surface
                    onClicked: {
                        const w = Hub.wallpapers.filter(x => x !== Theme.wallpaper)
                        if (w.length) Hub.setWallpaper(w[Math.floor(Math.random() * w.length)])
                    }
                }
            }
        }

        GridView {
            id: grid
            width: parent.width
            height: parent.height - 54
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 9 / 16 + 12
            model: Hub.wallpapers
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property bool cur: modelData === Theme.wallpaper
                width: grid.cellWidth; height: grid.cellHeight

                opacity: 0
                scale: 0.85
                Component.onCompleted: pop.start()
                SequentialAnimation {
                    id: pop
                    PauseAnimation { duration: Theme.dur(Math.min(cell.index, 16) * 25) }
                    ParallelAnimation {
                        NumberAnimation { target: cell; property: "opacity"; to: 1; duration: Theme.dur(280) }
                        NumberAnimation { target: cell; property: "scale"; to: 1; duration: Theme.dur(420); easing.type: Easing.OutBack }
                    }
                }

                Rectangle {
                    id: frame
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 16
                    color: Theme.surface
                    border.width: cell.cur ? 3 : 0
                    border.color: Theme.accent
                    scale: ma.containsMouse ? 1.04 : 1
                    z: ma.containsMouse ? 2 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }

                    Image {
                        id: thumb
                        anchors.fill: parent
                        anchors.margins: cell.cur ? 3 : 0
                        source: "file://" + cell.modelData
                        sourceSize: Qt.size(400, 225)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    Rectangle {
                        id: mask
                        anchors.fill: thumb
                        radius: 14
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: thumb
                        source: thumb
                        maskEnabled: true
                        maskSource: mask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }

                    Glyph {
                        anchors.centerIn: parent
                        visible: thumb.status !== Image.Ready
                        text: Icons.image; size: 30
                        color: Theme.textDim
                        opacity: thumb.status === Image.Error ? 0.5 : 0.25
                    }
                    Rectangle {
                        visible: cell.cur
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                        width: 26; height: 26; radius: 13
                        color: Theme.accent
                        Glyph { anchors.centerIn: parent; text: Icons.check; size: 15; color: Theme.onAccent }
                    }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hub.setWallpaper(cell.modelData)
                }
            }
        }
    }
}
