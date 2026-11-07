import QtQuick
import ".."
import "../components"

// "Blob" tab: settings of the desktop blob (~/quickdots/blobball), which
// used to have its own little menu. Left: live preview + visibility,
// process status and test message. Right: looks and behavior in two
// columns. Every change is written to blob.json right away (BlobStore) and
// the running blob reloads it -- no "Anwenden" needed.
FocusScope {
    id: page

    readonly property color previewColor: BlobStore.blobAdaptiveTheme ? BlobStore.walAccent : BlobStore.blobColor

    component SectionLabel: Text {
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXs
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    component SubLabel: Text {
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontS
    }

    // Pill row for small string choices (Schrift: Auto/Schwarz/Weiß).
    component Pills: Row {
        id: pills
        property var options: []
        property string selected: ""
        signal picked(string key)
        spacing: 6
        Repeater {
            model: pills.options
            delegate: Rectangle {
                id: pill
                required property var modelData
                readonly property bool active: pills.selected === modelData.key
                width: pillText.implicitWidth + 22
                height: 26
                radius: height / 2
                color: active ? Qt.alpha(Theme.accent, 0.18) : (pillMouse.containsMouse ? Theme.panelAlt : "transparent")
                border.width: Theme.borderWidth
                border.color: active ? Qt.alpha(Theme.accent, 0.7) : Theme.border
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: pill.modelData.label
                    color: pill.active ? Theme.text : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                }
                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pills.picked(pill.modelData.key)
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // -- Preview -----------------------------------------------------
        Panel {
            id: previewPanel
            width: Math.round(parent.width * 0.32)
            height: parent.height

            Item {
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                Text {
                    id: title
                    anchors { top: parent.top; left: parent.left }
                    text: "Blob"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontXl
                    font.weight: Font.Bold
                }

                // Process status: running / not running (+ start)
                Row {
                    id: status
                    anchors { left: title.right; leftMargin: Theme.spacingM; verticalCenter: title.verticalCenter; verticalCenterOffset: 2 }
                    spacing: 6
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        color: BlobStore.running ? Theme.success : Theme.danger
                    }
                    Text {
                        text: BlobStore.running ? "läuft" : "nicht gestartet"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                }

                Text {
                    id: pathText
                    anchors { top: title.bottom; topMargin: 2; left: parent.left; right: parent.right }
                    elide: Text.ElideMiddle
                    text: "quickdots/blobball  ·  ~/.local/state/quickshell/blob.json"
                    color: Theme.textFaint
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontXs
                }

                // Stage: the blob in its real pixel size (40..240 px).
                Rectangle {
                    id: stage
                    anchors { top: pathText.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right; bottom: controls.top; bottomMargin: Theme.spacingM }
                    radius: Theme.radiusSmall
                    color: Theme.bg
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    clip: true

                    // Dotted grid as a "desktop"
                    Canvas {
                        anchors.fill: parent
                        opacity: 0.5
                        onPaint: {
                            const c = getContext("2d");
                            c.reset();
                            c.fillStyle = Theme.border;
                            for (let x = 12; x < width; x += 18)
                                for (let y = 12; y < height; y += 18)
                                    c.fillRect(x, y, 1.5, 1.5);
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Blob {
                        anchors.centerIn: parent
                        size: Math.min(BlobStore.blobSize, stage.width - 24, stage.height - 24)
                        shapeKind: BlobStore.blobShape
                        blobColor: page.previewColor
                        jiggle: BlobStore.jiggleAmount
                        atRest: true
                        opacity: BlobStore.blobVisible ? 1 : 0.25
                        Behavior on size { NumberAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                    }

                    Text {
                        anchors { bottom: parent.bottom; right: parent.right; margins: Theme.spacingS }
                        text: Math.round(BlobStore.blobSize) + " px"
                              + (BlobStore.blobSize > Math.min(stage.width, stage.height) - 24 ? "  (verkleinert)" : "")
                        color: Theme.textFaint
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontXs
                    }
                    Text {
                        visible: !BlobStore.blobVisible
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Theme.spacingS }
                        text: "ausgeblendet"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                }

                Column {
                    id: controls
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: Theme.spacingM

                    ToggleRow {
                        width: parent.width
                        label: "Sichtbar"
                        hint: "Blob auf dem Desktop ein-/ausblenden"
                        checked: BlobStore.blobVisible
                        onToggled: v => BlobStore.set("blobVisible", v)
                    }

                    Row {
                        spacing: Theme.spacingS
                        WizardButton {
                            visible: !BlobStore.running
                            text: "Starten"
                            icon: ""
                            primary: true
                            onClicked: BlobStore.start()
                        }
                        WizardButton {
                            visible: BlobStore.running
                            text: "Test-Nachricht"
                            icon: ""
                            enabled: BlobStore.blobVisible
                            onClicked: BlobStore.testMessage()
                        }
                        WizardButton {
                            text: "Standard"
                            icon: ""
                            onClicked: BlobStore.resetDefaults()
                        }
                    }
                }
            }
        }

        // -- Settings ----------------------------------------------------
        Panel {
            id: settingsPanel
            width: parent.width - previewPanel.width - parent.spacing
            height: parent.height

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                contentHeight: columns.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: columns
                    width: flick.width
                    spacing: Theme.spacingXl
                    readonly property real colWidth: (width - spacing) / 2

                    // -- Looks ------------------------------------------
                    Column {
                        width: columns.colWidth
                        spacing: Theme.spacingM

                        SectionLabel { text: "AUSSEHEN" }

                        SubLabel { text: "Form" }
                        Row {
                            spacing: Theme.spacingS
                            Repeater {
                                model: [
                                    { key: "circle", label: "Kreis" },
                                    { key: "roundedSquare", label: "Quadrat" },
                                    { key: "squircle", label: "Squircle" },
                                    { key: "organic", label: "Organisch" }
                                ]
                                delegate: Rectangle {
                                    id: shapeOpt
                                    required property var modelData
                                    readonly property bool active: BlobStore.blobShape === modelData.key
                                    width: (columns.colWidth - 3 * Theme.spacingS) / 4
                                    height: 72
                                    radius: Theme.radiusSmall
                                    color: active ? Qt.alpha(Theme.accent, 0.14) : (shapeMouse.containsMouse ? Theme.panelAlt : "transparent")
                                    border.width: Theme.borderWidth
                                    border.color: active ? Qt.alpha(Theme.accent, 0.7) : Theme.border
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Blob {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 8
                                        size: 34
                                        shapeKind: shapeOpt.modelData.key
                                        blobColor: page.previewColor
                                        atRest: true
                                    }
                                    Text {
                                        anchors { bottom: parent.bottom; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                                        text: shapeOpt.modelData.label
                                        color: shapeOpt.active ? Theme.text : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontXs
                                    }
                                    MouseArea {
                                        id: shapeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BlobStore.set("blobShape", shapeOpt.modelData.key)
                                    }
                                }
                            }
                        }

                        SliderRow {
                            width: parent.width
                            label: "Größe"
                            from: 40; to: 240; decimals: 0; suffix: " px"
                            value: BlobStore.blobSize
                            onMoved: v => BlobStore.set("blobSize", v)
                        }

                        SliderRow {
                            width: parent.width
                            label: "Wabbeligkeit"
                            from: 0; to: 2; decimals: 2
                            value: BlobStore.jiggleAmount
                            onMoved: v => BlobStore.set("jiggleAmount", v)
                        }

                        SubLabel { text: "Farbe" }
                        Row {
                            spacing: 10
                            enabled: !BlobStore.blobAdaptiveTheme
                            opacity: enabled ? 1 : 0.35
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            Repeater {
                                model: BlobStore.colors
                                delegate: Rectangle {
                                    id: swatch
                                    required property string modelData
                                    readonly property bool active: BlobStore.blobColor.toLowerCase() === modelData
                                    width: 26; height: 26; radius: 13
                                    color: modelData
                                    border.width: active ? 2 : 0
                                    border.color: Theme.text
                                    scale: active ? 1.15 : (swatchMouse.containsMouse ? 1.08 : 1)
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                                    MouseArea {
                                        id: swatchMouse
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BlobStore.set("blobColor", swatch.modelData)
                                    }
                                }
                            }
                        }

                        ToggleRow {
                            width: parent.width
                            label: "Adaptives Theme"
                            hint: "Farbe live aus dem aktuellen Wallpaper"
                            checked: BlobStore.blobAdaptiveTheme
                            onToggled: v => BlobStore.set("blobAdaptiveTheme", v)
                        }

                        SubLabel { text: "Schrift in Nachrichten" }
                        Pills {
                            options: [
                                { key: "auto", label: "Auto" },
                                { key: "black", label: "Schwarz" },
                                { key: "white", label: "Weiß" }
                            ]
                            selected: BlobStore.textColorMode
                            onPicked: k => BlobStore.set("textColorMode", k)
                        }
                    }

                    // -- Behavior ---------------------------------------
                    Column {
                        width: columns.colWidth
                        spacing: Theme.spacingM

                        SectionLabel { text: "VERHALTEN" }

                        SliderRow {
                            width: parent.width
                            label: "Abprall (Restitution)"
                            from: 0.2; to: 0.98; decimals: 2
                            value: BlobStore.restitution
                            onMoved: v => BlobStore.set("restitution", v)
                        }

                        ToggleRow {
                            width: parent.width
                            label: "Schwerkraft"
                            hint: "Blob fällt nach unten statt zu schweben"
                            checked: BlobStore.gravityEnabled
                            onToggled: v => BlobStore.set("gravityEnabled", v)
                        }

                        ToggleRow {
                            width: parent.width
                            label: "In Ecke fliegen, wenn inaktiv"
                            hint: "Klick auf den geparkten Blob zeigt den Nachrichten-Verlauf"
                            checked: BlobStore.idleToCornerEnabled
                            onToggled: v => BlobStore.set("idleToCornerEnabled", v)
                        }

                        SliderRow {
                            width: parent.width
                            enabled: BlobStore.idleToCornerEnabled
                            label: "Wartezeit bis Ecke"
                            from: 0; to: 30; decimals: 0; suffix: " s"
                            value: BlobStore.idleToCornerDelay
                            onMoved: v => BlobStore.set("idleToCornerDelay", v)
                        }

                        SubLabel { text: "Ecke"; opacity: BlobStore.idleToCornerEnabled ? 1 : 0.4 }
                        Row {
                            spacing: Theme.spacingS
                            enabled: BlobStore.idleToCornerEnabled
                            opacity: enabled ? 1 : 0.4
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            Repeater {
                                model: [
                                    { key: "nearest" },
                                    { key: "topLeft" },
                                    { key: "topRight" },
                                    { key: "bottomLeft" },
                                    { key: "bottomRight" }
                                ]
                                delegate: Rectangle {
                                    id: corner
                                    required property var modelData
                                    readonly property bool active: BlobStore.idleCorner === modelData.key
                                    readonly property bool isLeft: modelData.key === "topLeft" || modelData.key === "bottomLeft"
                                    readonly property bool isTop: modelData.key === "topLeft" || modelData.key === "topRight"
                                    width: 46; height: 46
                                    radius: Theme.radiusSmall
                                    color: active ? Qt.alpha(Theme.accent, 0.14) : (cornerMouse.containsMouse ? Theme.panelAlt : "transparent")
                                    border.width: Theme.borderWidth
                                    border.color: active ? Qt.alpha(Theme.accent, 0.7) : Theme.border

                                    // Mini screen with the target corner
                                    Rectangle {
                                        id: screen
                                        anchors.centerIn: parent
                                        width: 28; height: 22; radius: 4
                                        color: Theme.bg
                                        border.width: 1
                                        border.color: corner.active ? Theme.accent : Theme.textFaint
                                        Rectangle {
                                            visible: corner.modelData.key !== "nearest"
                                            width: 7; height: 7; radius: 3.5
                                            color: corner.active ? Theme.accent : Theme.textDim
                                            x: corner.isLeft ? 3 : parent.width - width - 3
                                            y: corner.isTop ? 3 : parent.height - height - 3
                                        }
                                        Repeater {
                                            model: corner.modelData.key === "nearest" ? 4 : 0
                                            delegate: Rectangle {
                                                required property int index
                                                width: 4; height: 4; radius: 2
                                                color: corner.active ? Theme.accent : Theme.textFaint
                                                x: index % 2 === 0 ? 3 : screen.width - width - 3
                                                y: index < 2 ? 3 : screen.height - height - 3
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: cornerMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BlobStore.set("idleCorner", corner.modelData.key)
                                    }
                                }
                            }
                        }

                        SliderRow {
                            width: parent.width
                            label: "Sicherheitsabstand oben (Bars)"
                            from: 0; to: 120; decimals: 0; suffix: " px"
                            value: BlobStore.barMargin
                            onMoved: v => BlobStore.set("barMargin", v)
                        }
                    }
                }
            }

            Rectangle {
                visible: flick.contentHeight > flick.height
                anchors.right: parent.right
                anchors.rightMargin: 4
                y: flick.y + flick.visibleArea.yPosition * flick.height
                width: 3
                height: flick.visibleArea.heightRatio * flick.height
                radius: 1.5
                color: Theme.textFaint
                opacity: flick.moving ? 0.9 : 0.4
            }
        }
    }
}
