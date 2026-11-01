import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper switcher: thumbnail grid, hover tilt + scale, applies via awww
// (live transition) and re-runs pywal so Theme's "adaptive" mode (and any
// other bar reading ~/.cache/wal/colors.json) stays in sync.
Item {
    id: root

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
    property var wallpapers: []

    Process {
        id: lsProc
        running: true
        command: ["sh", "-c", "ls -1 \"" + root.wallpaperDir + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n")
                    .map(f => f.trim())
                    .filter(f => /\.(png|jpg|jpeg|webp|bmp)$/i.test(f))
                    .map(f => root.wallpaperDir + "/" + f);
            }
        }
    }

    function pickWallpaper(path) {
        Settings.setWallpaperPath(path);
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "any", "--transition-fps", "60"]);
        Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: grid.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            width: parent.width
            columns: 4
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: root.wallpapers
                delegate: Item {
                    id: thumb
                    required property string modelData
                    required property int index
                    width: (grid.width - 3 * grid.columnSpacing) / grid.columns
                    height: width * 0.62

                    readonly property bool current: Settings.wallpaperPath === thumb.modelData

                    opacity: 0
                    Component.onCompleted: entrance.start()
                    SequentialAnimation {
                        id: entrance
                        PauseAnimation { duration: thumb.index * 25 }
                        NumberAnimation { target: thumb; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: Theme.radiusMed
                        color: Theme.surfaceAlt
                        clip: true
                        border.width: thumb.current ? 2 : 0
                        border.color: Theme.accent2
                        Behavior on border.width { NumberAnimation { duration: Theme.animFast } }

                        scale: hoverArea.containsMouse ? 1.06 : 1
                        rotation: hoverArea.containsMouse ? (thumb.index % 2 === 0 ? -1.5 : 1.5) : 0
                        Behavior on scale { SpringAnimation { spring: 3; damping: 0.35 } }
                        Behavior on rotation { SpringAnimation { spring: 3; damping: 0.35 } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + thumb.modelData
                            fillMode: Image.PreserveAspectCrop
                            // Wallpapers here can be 10+ MB phone photos --
                            // without sourceSize, Qt fully decodes each one
                            // just to show a ~140px thumbnail, which chokes
                            // the async decode queue and leaves most of the
                            // grid blank for many seconds after opening.
                            sourceSize.width: 220
                            sourceSize.height: 140
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 6
                            width: 20; height: 20; radius: 10
                            color: Theme.accent2
                            visible: thumb.current
                            scale: visible ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                            Icon { anchors.centerIn: parent; name: "checkmark"; size: 11; tint: Theme.bg }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pickWallpaper(thumb.modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.wallpapers.length === 0
            text: "Keine Hintergrundbilder in ~/Pictures/Walpapers"
            color: Theme.textDim
            font.pixelSize: 13
            font.italic: true
        }
    }
}
