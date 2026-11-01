import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// A horizontal filmstrip rather than a grid -- picking a wallpaper here
// reads more like flipping through a stack of prints than filling a
// spreadsheet of thumbnails.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.wallpaperWidth
    panelHeight: Metrics.wallpaperHeight

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
    property var wallpapers: []
    readonly property int cardWidth: 190

    Connections {
        target: Popups
        function onFocusTokenChanged() {
            if (Popups.openId === "wallpapers")
                strip.forceActiveFocus();
        }
    }

    onWallpapersChanged: Qt.callLater(function () {
        const idx = root.wallpapers.indexOf(Config.lastWallpaper);
        strip.currentIndex = idx >= 0 ? idx : 0;
    })

    Process {
        id: lister
        running: root.shown && root.wallpapers.length === 0
        command: ["sh", "-c", "ls -1 \"" + root.wallpaperDir + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n")
                    .map(n => n.trim())
                    .filter(n => /\.(png|jpe?g|webp|bmp)$/i.test(n))
                    .map(n => root.wallpaperDir + "/" + n);
            }
        }
    }

    function pick(path) {
        Config.setLastWallpaper(path);
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "any", "--transition-fps", "60"]);
        Quickshell.execDetached(["wal", "-i", path, "-n", "-q"]);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            text: "Hintergrundbild"
            color: Chroma.textFaint
            font.family: Metrics.fontFamily
            font.pixelSize: 11
        }

        ListView {
            id: strip
            width: parent.width
            height: parent.height - 26
            clip: true
            orientation: ListView.Horizontal
            spacing: 10
            focus: true
            keyNavigationEnabled: true
            preferredHighlightBegin: Math.max(0, (strip.width - root.cardWidth) / 2)
            preferredHighlightEnd: strip.preferredHighlightBegin + root.cardWidth
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: Metrics.popupAnimMs

            Keys.onReturnPressed: root.pick(root.wallpapers[strip.currentIndex])
            Keys.onEnterPressed: root.pick(root.wallpapers[strip.currentIndex])

            model: root.wallpapers
            delegate: Item {
                id: card
                required property string modelData
                required property int index
                width: root.cardWidth
                height: strip.height
                readonly property bool applied: Config.lastWallpaper === card.modelData
                readonly property bool highlighted: card.ListView.isCurrentItem

                opacity: 0
                Component.onCompleted: entrance.start()
                SequentialAnimation {
                    id: entrance
                    PauseAnimation { duration: card.index * 40 }
                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    id: frame
                    anchors.fill: parent
                    radius: Chroma.rMed
                    color: Chroma.panelRaised
                    clip: true
                    border.width: (card.applied || card.highlighted) ? 2 : 0
                    border.color: card.applied ? Chroma.accent2 : Chroma.accent
                    Behavior on border.width { NumberAnimation { duration: Chroma.tFast } }
                    Behavior on border.color { ColorAnimation { duration: Chroma.tFast } }

                    scale: (hoverArea.containsMouse || card.highlighted) ? 1.04 : 1
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.35 } }

                    Image {
                        anchors.fill: parent
                        source: "file://" + card.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 260
                        sourceSize.height: 200
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 18; height: 18; radius: 9
                        color: Chroma.accent2
                        visible: card.applied
                        scale: visible ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: Chroma.tFast; easing.type: Easing.OutBack } }
                        Glyph { anchors.centerIn: parent; name: "check"; width: 10; height: 10; tint: Chroma.ink }
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        strip.currentIndex = card.index;
                        root.pick(card.modelData);
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.wallpapers.length === 0
                text: "Keine Bilder in ~/Pictures/Walpapers"
                color: Chroma.textFaint
                font.family: Metrics.fontFamily
                font.pixelSize: 12
                font.italic: true
            }
        }
    }
}
