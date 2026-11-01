import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".."
import "../components"

// "Blur" tab: mango's global blur (behind bars, menus and translucent
// windows). Left: approximate preview -- current wallpaper with a glass card
// whose backdrop is blurred like mango would. Right: the options. Every
// change is written to config.conf and reloaded live (BlobStore pattern, no
// "Anwenden"), so the real blur on screen is the actual preview.
FocusScope {
    id: page

    property string wallpaper: ""
    // the preview is a fraction of the screen, so scale the blur radius down too
    readonly property real previewEffective: BlurStore.radius * Math.pow(2, BlurStore.passes) * (stage.width / 2560)

    Process {
        running: true
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
        stdout: StdioCollector { onStreamFinished: page.wallpaper = text.trim() }
    }

    component SectionLabel: Text {
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXs
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // -- Preview -----------------------------------------------------
        Panel {
            id: previewPanel
            width: Math.round(parent.width * 0.42)
            height: parent.height

            Item {
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                Text {
                    id: title
                    anchors { top: parent.top; left: parent.left }
                    text: "Blur"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontXl
                    font.weight: Font.Bold
                }
                Text {
                    id: pathText
                    anchors { top: title.bottom; topMargin: 2; left: parent.left; right: parent.right }
                    elide: Text.ElideMiddle
                    text: "~/.config/mango/config.conf  ·  gilt für alle Bars"
                    color: Theme.textFaint
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontXs
                }

                ClippingRectangle {
                    id: stage
                    anchors { top: pathText.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right }
                    height: width * 9 / 16
                    radius: Theme.radiusSmall
                    color: Theme.bg


                    Image {
                        id: wall
                        anchors.fill: parent
                        source: page.wallpaper !== "" ? "file://" + page.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 640
                        asynchronous: true
                    }

                    // glass card: blurred copy of the wallpaper, clipped to the card
                    ClippingRectangle {
                        id: card
                        anchors.centerIn: parent
                        width: parent.width * 0.62
                        height: parent.height * 0.5
                        radius: 14
                        color: "transparent"

                        MultiEffect {
                            x: -card.x
                            y: -card.y
                            width: stage.width
                            height: stage.height
                            source: wall
                            visible: BlurStore.blur && BlurStore.blurLayer
                            blurEnabled: true
                            blurMax: 64
                            blur: Math.min(1, page.previewEffective / 32)
                            brightness: BlurStore.brightness - 1
                            contrast: BlurStore.contrast - 1
                            saturation: BlurStore.saturation - 1
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: card.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.rgba(24 / 255, 36 / 255, 26 / 255, 0.70) }
                                GradientStop { position: 1; color: Qt.rgba(70 / 255, 28 / 255, 40 / 255, 0.55) }
                            }
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                        }
                        Text {
                            anchors.centerIn: parent
                            text: BlurStore.blur && BlurStore.blurLayer ? "Glas" : "Blur aus"
                            color: "#E8EDE6"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontL
                            font.weight: Font.Bold
                        }
                    }
                }

                Text {
                    anchors { top: stage.bottom; topMargin: Theme.spacingS; left: parent.left; right: parent.right }
                    wrapMode: Text.WordWrap
                    text: "Vorschau ist eine Annäherung – der echte Blur hinter Bar und Menüs ändert sich sofort mit. "
                        + "Stärke ≈ Radius × 2^Durchgänge = " + Math.round(BlurStore.radius * Math.pow(2, BlurStore.passes)) + " px."
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                }

                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: Theme.spacingS
                    Text {
                        visible: BlurStore.lastError !== ""
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: BlurStore.lastError
                        color: Theme.danger
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                    WizardButton {
                        text: "Standard"
                        icon: ""
                        onClicked: BlurStore.resetDefaults()
                    }
                }
            }
        }

        // -- Settings ----------------------------------------------------
        Panel {
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

                    Column {
                        width: columns.colWidth
                        spacing: Theme.spacingM
                        SectionLabel { text: "STÄRKE" }
                        ToggleRow {
                            width: parent.width
                            label: "Blur an"
                            hint: "Fenster und Oberflächen"
                            checked: BlurStore.blur
                            onToggled: v => BlurStore.set("blur", v)
                        }
                        ToggleRow {
                            width: parent.width
                            enabled: BlurStore.blur
                            label: "Bar & Menüs"
                            hint: "Layer-Blur (nur qs-* Oberflächen)"
                            checked: BlurStore.blurLayer
                            onToggled: v => BlurStore.set("blurLayer", v)
                        }
                        SliderRow {
                            width: parent.width
                            enabled: BlurStore.blur
                            label: "Radius"
                            from: 1; to: 20; decimals: 0
                            value: BlurStore.radius
                            onMoved: v => BlurStore.set("radius", v)
                        }
                        SliderRow {
                            width: parent.width
                            enabled: BlurStore.blur
                            label: "Durchgänge"
                            from: 1; to: 6; decimals: 0
                            value: BlurStore.passes
                            onMoved: v => BlurStore.set("passes", v)
                        }
                        ToggleRow {
                            width: parent.width
                            enabled: BlurStore.blur
                            label: "Optimiert"
                            hint: "spart viel GPU – empfohlen"
                            checked: BlurStore.blurOptimized
                            onToggled: v => BlurStore.set("blurOptimized", v)
                        }
                    }

                    Column {
                        width: columns.colWidth
                        spacing: Theme.spacingM
                        enabled: BlurStore.blur
                        opacity: enabled ? 1 : 0.4
                        SectionLabel { text: "LOOK" }
                        SliderRow {
                            width: parent.width
                            label: "Helligkeit"
                            from: 0.3; to: 1; decimals: 2
                            value: BlurStore.brightness
                            onMoved: v => BlurStore.set("brightness", v)
                        }
                        SliderRow {
                            width: parent.width
                            label: "Kontrast"
                            from: 0.3; to: 1; decimals: 2
                            value: BlurStore.contrast
                            onMoved: v => BlurStore.set("contrast", v)
                        }
                        SliderRow {
                            width: parent.width
                            label: "Sättigung"
                            from: 0; to: 1; decimals: 2
                            value: BlurStore.saturation
                            onMoved: v => BlurStore.set("saturation", v)
                        }
                        SliderRow {
                            width: parent.width
                            label: "Rauschen"
                            from: 0; to: 0.2; decimals: 2
                            value: BlurStore.noise
                            onMoved: v => BlurStore.set("noise", v)
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Mango begrenzt Helligkeit, Kontrast und Sättigung auf höchstens 1.0."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXs
                        }
                    }
                }
            }
        }
    }
}
