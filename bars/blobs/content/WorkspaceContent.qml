import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Geoeffnete linke Kugel (Auftrag Abschnitt 4): Transparenz-Slider +
// Wallpaper-Grid.
Item {
    id: root

    // Echter Ordner -- ~/Pictures/Wallpaper aus dem Auftrag
    // existiert nicht, siehe README "Abweichungen vom Ursprungs-Prompt".
    readonly property string _wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
    property var _files: []
    property string _activePath: ""

    Process {
        running: true
        command: ["sh", "-c", "ls -1 \"" + root._wallpaperDir + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const exts = ["jpg", "jpeg", "png", "webp"];
                root._files = text.split("\n").filter(f => f.length > 0 && exts.includes(f.split(".").pop().toLowerCase())).map(f => root._wallpaperDir + "/" + f);
            }
        }
    }

    function setWallpaper(path) {
        root._activePath = path;
        // matugen setzt das Wallpaper selbst (config.wallpaper.command =
        // "awww img {{ image }}" in ~/.config/matugen/config.toml) und
        // schreibt die neue Palette -- ein Aufruf statt awww + matugen
        // einzeln. Theme.qml uebernimmt die Farben automatisch
        // (FileView watchChanges), kein expliziter Reload noetig.
        Quickshell.execDetached(["matugen", "image", path]);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Row {
            width: parent.width
            spacing: 6

            Text {
                text: "Transparenz"
                color: Theme.surfaceInk
                font.pixelSize: 10
                width: 58
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: opacitySlider
                width: parent.width - 58 - 30
                height: 14
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: Theme.outline
                }
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, Settings.barOpacity))
                    height: 3
                    radius: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => opacitySlider._setFromX(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            opacitySlider._setFromX(mouse.x);
                    }
                    // Erst beim Loslassen schreiben, nicht bei jeder
                    // Zwischenposition waehrend des Drags (Settings.qml).
                    onReleased: Settings.save()
                }

                function _setFromX(px) {
                    Settings.barOpacity = Math.max(0, Math.min(1, px / width));
                }
            }

            Text {
                text: Math.round(Settings.barOpacity * 100) + "%"
                color: Theme.surfaceInk
                font.pixelSize: 10
                width: 30
            }
        }

        // Grid kann mehr Zeilen enthalten, als in die feste Panelhoehe passen
        // (z.B. 41 Bilder / 4 Spalten = 11 Zeilen a 60px, Panel hat nur noch
        // ~180px nach Slider+Spacing übrig) -- ohne Flickable wurde der Rest
        // vom `clip: true` der umgebenden MorphBlob-Flaeche einfach
        // unsichtbar abgeschnitten, nicht nur optisch verdeckt.
        Flickable {
            id: wallpaperFlick
            width: parent.width
            height: parent.height - y
            contentWidth: width
            contentHeight: wallpaperGrid.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: wallpaperGrid
                columns: 4
                spacing: 4
                width: parent.width

                Repeater {
                    model: root._files

                    Rectangle {
                        id: thumb
                        required property string modelData

                        width: 56
                        height: 56
                        radius: 6
                        color: Theme.surface
                        border.width: root._activePath === thumb.modelData ? 2 : 0
                        border.color: Theme.primary
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: thumb.border.width
                            source: "file://" + thumb.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(64, 64)
                            cache: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.setWallpaper(thumb.modelData)
                        }
                    }
                }

                Text {
                    visible: root._files.length === 0
                    text: "Keine Wallpaper gefunden"
                    color: Theme.surfaceInk
                    opacity: 0.5
                    font.pixelSize: 10
                }
            }

            Rectangle {
                // Minimaler Scrollbar-Indikator -- kein QtQuick.Controls.
                // ScrollBar irgendwo sonst in diesem Repo (Konvention:
                // eigene Mini-Slider statt Controls-Import).
                visible: wallpaperFlick.contentHeight > wallpaperFlick.height
                anchors.right: parent.right
                width: 3
                radius: 1.5
                color: Theme.outline
                y: (wallpaperFlick.contentHeight > 0) ? wallpaperFlick.visibleArea.yPosition * wallpaperFlick.height : 0
                height: (wallpaperFlick.contentHeight > 0) ? wallpaperFlick.visibleArea.heightRatio * wallpaperFlick.height : 0
            }
        }
    }
}
