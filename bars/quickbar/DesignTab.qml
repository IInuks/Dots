import QtQuick
import Quickshell
import Quickshell.Io

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var modes: [
        { key: "dark", label: "Dunkel", desc: "Dunkle Bar, weiße Icons und Schrift.", pal: Theme.dark },
        { key: "light", label: "Hell", desc: "Helle Bar, schwarze Icons und Schrift.", pal: Theme.light },
        { key: "adaptive", label: "Adaptiv", desc: "Echte Farben aus dem Hintergrundbild extrahiert.", pal: Theme.adaptivePalette || Theme.dark }
    ]

    property var wallpapers: []

    Process {
        id: lsProc
        running: true
        command: ["sh", "-c", "ls -1 \"" + Quickshell.env("HOME") + "/Pictures/Walpapers\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = Quickshell.env("HOME") + "/Pictures/Walpapers/";
                root.wallpapers = text.split("\n")
                    .filter(f => /\.(png|jpg|jpeg|webp|bmp)$/i.test(f))
                    .map(f => dir + f);
            }
        }
    }

    function pickWallpaper(path) {
        Settings.setWallpaperPath(path);
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "any", "--transition-fps", "60"]);
        Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
    }

    Column {
        id: col
        width: root.width
        spacing: 18

        Column {
            width: parent.width
            spacing: 6
            Text { text: "Farbschema"; color: Theme.textDim; font.pixelSize: 11 }

            Repeater {
                model: root.modes
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: col.width
                    height: 52
                    radius: Theme.radiusMed
                    color: Theme.mode === modelData.key ? Theme.surfaceAlt : "transparent"
                    border.width: Theme.mode === modelData.key ? 1 : 0
                    border.color: Theme.accent

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Rectangle {
                            width: 30; height: 30; radius: 8
                            color: card.modelData.pal.bg
                            border.width: 1
                            border.color: Theme.surfaceAlt
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                anchors.centerIn: parent
                                color: card.modelData.pal.accent
                            }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: card.modelData.label; color: Theme.text; font.pixelSize: 13; font.bold: true }
                            Text { width: 220; wrapMode: Text.WordWrap; text: card.modelData.desc; color: Theme.textDim; font.pixelSize: 11 }
                        }
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
            spacing: 6
            Text { text: "Hintergrundbild"; color: Theme.textDim; font.pixelSize: 11 }

            Grid {
                width: parent.width
                columns: 4
                spacing: 6

                Repeater {
                    model: root.wallpapers
                    delegate: Rectangle {
                        id: thumb
                        required property string modelData
                        width: (col.width - 3 * 6) / 4
                        height: width * 0.65
                        radius: Theme.radiusSmall
                        color: Theme.surfaceAlt
                        border.width: Settings.wallpaperPath === modelData ? 2 : 0
                        border.color: Theme.accent
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + thumb.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickWallpaper(thumb.modelData)
                        }
                    }
                }
            }
        }
    }
}
