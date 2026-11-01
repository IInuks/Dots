import QtQuick
import "../"
import "../Bar"

// Tags-Panelinhalt: klickbares Raster aller mango-Tags dieses Bildschirms
// (aktive hervorgehoben, belegte mit Füllfarbe, dringende rot umrandet --
// gleiches Datenschema wie MangoService.tagsFor(), schon dokumentiert und
// verifiziert in bars/chamaeleon/bars/lumen) plus darunter die Fensterliste
// des/der gerade aktiven Tags. Klick auf ein Fenster fokussiert es
// (MangoService.focusClient, per `focusid` -- klappt nur für Fenster auf
// einem gerade angezeigten Tag, was die Liste hier per Konstruktion immer
// erfüllt), das X schließt es gezielt (MangoService.closeClient, per
// `killclient client,<id>`). Mango erlaubt mehrere gleichzeitig aktive
// Tags pro Monitor -- die Fensterliste ist deshalb eine Vereinigung über
// alle aktiven Tags, keine Gleichheitsprüfung gegen einen einzelnen Index.
Flickable {
    id: root

    required property string screenName

    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    readonly property var tags: MangoService.tagsFor(root.screenName)
    readonly property var activeIndices: MangoService.activeTagIndicesFor(root.screenName)
    readonly property var windows: {
        const active = root.activeIndices;
        return MangoService.clients.filter(c => c.monitor === root.screenName && c.tags && c.tags.some(t => active.indexOf(t) !== -1));
    }

    Column {
        id: layout
        width: root.width
        spacing: 14
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        Text {
            text: "Tags"
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.uiFontFamily
        }

        Grid {
            id: tagGrid
            width: parent.width - 28
            columns: 5
            spacing: 6

            Repeater {
                model: root.tags

                Rectangle {
                    id: tagSlot
                    required property var modelData
                    width: (tagGrid.width - (tagGrid.columns - 1) * tagGrid.spacing) / tagGrid.columns
                    height: width
                    radius: 8
                    color: tagSlot.modelData.is_active ? Theme.primary : (tagSlot.modelData.client_count > 0 ? Theme.surfaceVariant : "transparent")
                    border.width: 1
                    border.color: tagSlot.modelData.is_urgent ? Theme.critical : (tagSlot.modelData.is_active ? Theme.primary : Theme.outlineVariant)
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    Text {
                        anchors.centerIn: parent
                        text: tagSlot.modelData.index
                        color: tagSlot.modelData.is_urgent ? Theme.critical : (tagSlot.modelData.is_active ? Theme.primaryInk : Theme.surfaceVariantInk)
                        font.pixelSize: 12
                        font.bold: tagSlot.modelData.is_active
                        font.family: Theme.uiFontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MangoService.viewTag(root.screenName, tagSlot.modelData.index)
                    }
                }
            }
        }

        Text {
            visible: root.tags.length === 0
            text: "Keine Tags gemeldet"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        Column {
            width: parent.width - 28
            spacing: 8

            Repeater {
                model: root.windows

                // Plain Item, not a Row -- a Row would reject the
                // horizontal anchors.left/anchors.right needed for the
                // "click anywhere except the close icon" focus MouseArea
                // (Row only tolerates cross-axis anchors on its children,
                // e.g. TrayPanel.qml's anchors.verticalCenter, not along-
                // axis ones). Declared before closeIcon on purpose: later
                // siblings paint and hit-test on top, so closeIcon's own
                // MouseArea wins the few pixels of margin it shares with
                // this one, even though the anchor below already forward-
                // references closeIcon.left.
                Item {
                    id: winRow
                    required property var modelData
                    width: parent.width
                    height: 28

                    Icon {
                        id: winIcon
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: winRow.modelData.is_focused ? "check_circle" : "web_asset"
                        fallback: winRow.modelData.is_focused ? "*" : "▢"
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: winIcon.right
                        anchors.leftMargin: 8
                        anchors.right: closeIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: winRow.modelData.title || winRow.modelData.appid || "?"
                        color: winRow.modelData.is_focused ? Theme.surfaceInk : Theme.surfaceVariantInk
                        font.pixelSize: 11
                        font.family: Theme.uiFontFamily
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: closeIcon.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MangoService.focusClient(winRow.modelData.id)
                    }

                    Icon {
                        id: closeIcon
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "close"
                        fallback: "x"
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MangoService.closeClient(winRow.modelData.id)
                        }
                    }
                }
            }

            Text {
                visible: root.windows.length === 0
                text: "Keine Fenster auf diesem Tag"
                color: Theme.outline
                font.pixelSize: 11
                font.family: Theme.uiFontFamily
            }
        }
    }
}
