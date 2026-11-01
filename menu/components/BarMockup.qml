import QtQuick
import QtQuick.Effects
import ".."

// Large 16:9 preview for one bar. Uses bars/<name>/preview.png when the bar
// ships one (real screenshot); otherwise draws a mockup: the current
// wallpaper with a bar strip + two windows in that bar's own colors,
// opacity and corner radius (read via its own BarTheme).
Item {
    id: root

    property string barName: ""
    readonly property BarTheme theme: BarTheme { barName: root.barName }
    readonly property string screenshot: BarInfo.previewOf(barName)

    readonly property color surface: Qt.color(theme.surface)
    readonly property color fg: Qt.color(theme.foreground)
    readonly property color accent: Qt.color(theme.accent)
    // Mockup is roughly 1/3.5 of a 2560 px screen: scale radii to match.
    readonly property real k: width / 900

    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true

        // -- Real screenshot -------------------------------------------
        Image {
            anchors.fill: parent
            visible: root.screenshot.length > 0
            source: root.screenshot.length ? "file://" + root.screenshot : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }

        // -- Generated mockup ------------------------------------------
        Item {
            anchors.fill: parent
            visible: root.screenshot.length === 0

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.darker(root.accent, 2.6) }
                    GradientStop { position: 1; color: Qt.darker(root.surface, 1.2) }
                }
            }
            Image {
                id: wall
                anchors.fill: parent
                source: BarInfo.wallpaper.length ? "file://" + BarInfo.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 1280
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
            }

            // Bar strip
            Rectangle {
                id: strip
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 * root.k }
                height: 30 * root.k
                radius: Math.min(root.theme.radius * root.k * 0.8, height / 2)
                color: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, root.theme.barOpacity)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
                Behavior on color { ColorAnimation { duration: Theme.animPage } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.k
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * root.k
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            width: (index === 0 ? 22 : 9) * root.k
                            height: 9 * root.k
                            radius: height / 2
                            color: index === 0 ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, index < 3 ? 0.55 : 0.25)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatTime(new Date(), "HH:mm")
                    color: root.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13 * root.k
                    font.weight: Font.DemiBold
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * root.k
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.k
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: (index === 3 ? 26 : 11) * root.k
                            height: 11 * root.k
                            radius: index === 3 ? height / 2 : 3 * root.k
                            color: index === 3 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.8)
                                               : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
                        }
                    }
                }
            }

            // Two fake windows, tiled like mango would
            Repeater {
                model: [
                    { x: 0.022, w: 0.56, active: true },
                    { x: 0.594, w: 0.384, active: false }
                ]
                delegate: Rectangle {
                    required property var modelData
                    x: root.width * modelData.x
                    y: strip.y + strip.height + 10 * root.k
                    width: root.width * modelData.w
                    height: root.height - y - 12 * root.k
                    radius: 8 * root.k
                    color: Qt.rgba(root.surface.r * 0.9, root.surface.g * 0.9, root.surface.b * 0.9, 0.82)
                    border.width: modelData.active ? Math.max(1, 2 * root.k) : 1
                    border.color: modelData.active ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14 * root.k
                        spacing: 9 * root.k
                        Repeater {
                            model: 6
                            delegate: Rectangle {
                                required property int index
                                width: parent.width * [0.45, 0.8, 0.65, 0.72, 0.3, 0.55][index]
                                height: (index === 0 ? 10 : 6) * root.k
                                radius: height / 2
                                color: index === 0 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
                                                   : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Theme.radiusMid
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: content
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMid
        color: "transparent"
        border.width: Theme.borderWidth
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
    }

    Rectangle {
        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.spacingS }
        width: tag.implicitWidth + 14
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.55)
        Text {
            id: tag
            anchors.centerIn: parent
            text: root.screenshot.length ? "Screenshot" : "Vorschau (generiert)"
            color: "#d0d4d8"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXs
        }
    }
}
