import QtQuick
import Quickshell

// Real PopupWindow (Quickshell 0.3.0 Quickshell._Window/PopupWindow, read
// straight from the installed qmltypes -- parentWindow/anchor.item/
// anchor.edges/anchor.gravity/grabFocus). Anchored under the clock, closed
// by the click-away catcher in Bar.qml or Escape.
PopupWindow {
    id: root

    required property var hostWindow
    required property var anchorItem

    anchor.window: hostWindow
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    implicitWidth: 296
    implicitHeight: content.implicitHeight + 24
    color: Theme.surface // popup itself is always fully opaque, per spec
    visible: false
    grabFocus: root.visible

    readonly property var _tiles: Theme.themeList.concat([{ id: "adaptive", name: "Adaptiv", adaptive: true }])

    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.visible = false

        Column {
            id: content
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10

            Text { text: "Theme"; color: Theme.textMuted; font.pixelSize: 11 }

            Grid {
                width: parent.width
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: root._tiles
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        readonly property bool isAdaptive: !!modelData.adaptive
                        readonly property bool selected: Settings.themeId === modelData.id

                        width: (content.width - 8) / 2
                        height: 62
                        radius: 10
                        color: Theme.background
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.accent : Theme.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: modelData.name
                                color: Theme.text
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Row {
                                spacing: 4
                                visible: !tile.isAdaptive
                                Repeater {
                                    model: tile.isAdaptive ? [] : [modelData.background, modelData.surface, modelData.accent, modelData.urgent]
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 16; height: 16; radius: 3
                                        color: modelData
                                        border.width: 1
                                        border.color: Qt.alpha(Theme.text, 0.15)
                                    }
                                }
                            }

                            Text {
                                visible: tile.isAdaptive && !Theme.matugenAvailable && Theme.matugenChecked
                                text: "matugen nicht gefunden"
                                color: Theme.urgent
                                font.pixelSize: 9
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                            Text {
                                visible: tile.isAdaptive && Theme.matugenAvailable && !Theme.adaptivePalette
                                text: "noch nicht generiert"
                                color: Theme.textMuted
                                font.pixelSize: 9
                            }
                            Row {
                                spacing: 4
                                visible: tile.isAdaptive && Theme.matugenAvailable && !!Theme.adaptivePalette
                                Repeater {
                                    model: (tile.isAdaptive && Theme.adaptivePalette) ? [Theme.adaptivePalette.background, Theme.adaptivePalette.surface, Theme.adaptivePalette.accent, Theme.adaptivePalette.urgent] : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 16; height: 16; radius: 3
                                        color: modelData
                                        border.width: 1
                                        border.color: Qt.alpha(Theme.text, 0.15)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setThemeId(tile.modelData.id)
                        }
                    }
                }
            }

            Rectangle {
                visible: true
                width: parent.width
                height: 22
                radius: Theme.radiusSmall
                color: regenArea.containsMouse ? Qt.alpha(Theme.accent, 0.3) : Qt.alpha(Theme.accent, 0.18)
                Text {
                    anchors.centerIn: parent
                    text: "Neu generieren"
                    color: Theme.text
                    font.pixelSize: 11
                }
                MouseArea {
                    id: regenArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.regenerateAdaptive()
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Text { text: "Hintergrund-Transparenz"; color: Theme.textMuted; font.pixelSize: 11 }

            Row {
                width: parent.width
                spacing: 8

                Item {
                    width: parent.width - alphaLabel.width - 8
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: 2.5
                        color: Qt.alpha(Theme.textMuted, 0.3)
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Settings.backgroundAlpha
                        height: 5
                        radius: 2.5
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => Settings.setBackgroundAlpha(mouse.x / width)
                        onPositionChanged: mouse => { if (pressed) Settings.setBackgroundAlpha(mouse.x / width); }
                    }
                }

                Text {
                    id: alphaLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Settings.backgroundAlpha * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 11
                }
            }
        }
    }
}
