import QtQuick
import QtQuick.Effects
import ".."

// 16:9 preview for one launcher in the "Launcher" tab, shown the way it
// would be mixed: the current wallpaper with the *active* bar's strip (its
// own colors, ThemeAdapter), and on top the launcher card in the colors,
// opacity and radius of the bar it comes from (its own BarTheme). The app
// search ("appsearch") takes the active bar's colors, like the real one.
// Generated only -- "Ausprobieren" opens the real launcher.
Item {
    id: root

    property string launcherId: ""
    readonly property BarTheme theme: BarTheme {
        barName: root.launcherId === "appsearch" || root.launcherId === "" ? BarsModel.activeBar : root.launcherId
    }

    readonly property color surface: Qt.color(theme.surface)
    readonly property color fg: Qt.color(theme.foreground)
    readonly property color accent: Qt.color(theme.accent)
    readonly property color barSurface: Qt.color(ThemeAdapter.surface)
    readonly property color barFg: Qt.color(ThemeAdapter.foreground)
    readonly property color barAccent: Qt.color(ThemeAdapter.accent)
    readonly property real k: width / 900

    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.darker(root.barAccent, 2.6) }
                GradientStop { position: 1; color: Qt.darker(root.barSurface, 1.2) }
            }
        }
        Image {
            anchors.fill: parent
            source: BarInfo.wallpaper.length ? "file://" + BarInfo.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 1280
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
        }

        // The active bar, as it stays.
        Rectangle {
            id: strip
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 * root.k }
            height: 30 * root.k
            radius: Math.min(ThemeAdapter.radius * root.k * 0.8, height / 2)
            color: Qt.rgba(root.barSurface.r, root.barSurface.g, root.barSurface.b, ThemeAdapter.barOpacity)
            border.width: 1
            border.color: Qt.rgba(root.barAccent.r, root.barAccent.g, root.barAccent.b, 0.35)

            Row {
                anchors { left: parent.left; leftMargin: 12 * root.k; verticalCenter: parent.verticalCenter }
                spacing: 6 * root.k
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        width: (index === 0 ? 22 : 9) * root.k
                        height: 9 * root.k
                        radius: height / 2
                        color: index === 0 ? root.barAccent : Qt.rgba(root.barFg.r, root.barFg.g, root.barFg.b, index < 3 ? 0.55 : 0.25)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                text: Qt.formatTime(new Date(), "HH:mm")
                color: root.barFg
                font.family: Theme.fontFamily
                font.pixelSize: 13 * root.k
                font.weight: Font.DemiBold
            }
        }

        // Dim, like most launchers put behind themselves.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.32)
        }

        // The launcher card.
        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.2
            width: 330 * root.k
            height: col.implicitHeight + 28 * root.k
            radius: Math.min(Math.max(root.theme.radius, 8) * root.k * 1.1, 26 * root.k)
            color: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, Math.max(0.85, root.theme.barOpacity))
            border.width: 1
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
            Behavior on color { ColorAnimation { duration: Theme.animPage } }

            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 * root.k }
                spacing: 8 * root.k

                // Search field
                Rectangle {
                    width: parent.width
                    height: 30 * root.k
                    radius: Math.min(card.radius * 0.7, height / 2)
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
                    Row {
                        anchors { left: parent.left; leftMargin: 10 * root.k; verticalCenter: parent.verticalCenter }
                        spacing: 6 * root.k
                        Text {
                            text: ""
                            color: root.accent
                            font.family: Theme.monoFamily
                            font.pixelSize: 11 * root.k
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "fir"
                            color: root.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12 * root.k
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: Math.max(1, 1.5 * root.k)
                            height: 13 * root.k
                            color: root.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Repeater {
                    model: [0.42, 0.55, 0.36, 0.48, 0.3]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: col.width
                        height: 26 * root.k
                        radius: Math.min(card.radius * 0.5, height / 2)
                        color: index === 0 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85) : "transparent"
                        Rectangle {
                            id: ico
                            anchors { left: parent.left; leftMargin: 8 * root.k; verticalCenter: parent.verticalCenter }
                            width: 14 * root.k
                            height: width
                            radius: 4 * root.k
                            color: index === 0 ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
                        }
                        Rectangle {
                            anchors { left: ico.right; leftMargin: 8 * root.k; verticalCenter: parent.verticalCenter }
                            width: (col.width - 40 * root.k) * modelData
                            height: 6 * root.k
                            radius: height / 2
                            color: index === 0 ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.3)
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
            text: "Vorschau (generiert)  ·  „Ausprobieren“ zeigt das Original"
            color: "#d0d4d8"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXs
        }
    }
}
