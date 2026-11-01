import QtQuick
import ".."

// Theme controls for a custom bar: mode (dark/light/adaptive/custom colors),
// opacity, radius. Emits changed(key, value) for top-level theme fields --
// the caller (BarEditor) owns the actual theme object and merges these in.
Column {
    id: root

    property var theme: ({ mode: "dark", surface: "#1c1c26", foreground: "#e8e8f0", accent: "#5b8cff", opacity: 0.9, radius: 14 })

    signal changed(string key, var value)

    readonly property var _modes: [
        { key: "dark", label: "Dunkel" },
        { key: "light", label: "Hell" },
        { key: "adaptive", label: "Adaptiv" },
        { key: "custom", label: "Eigene Farben" }
    ]

    spacing: 10
    width: parent ? parent.width : 200

    Text {
        text: "Theme"
        color: Theme.foreground
        font.pixelSize: 12
        font.bold: true
    }

    Flow {
        width: root.width
        spacing: 4

        Repeater {
            model: root._modes
            delegate: Rectangle {
                id: modeBtn
                required property var modelData
                readonly property bool active: root.theme.mode === modelData.key
                width: modeLabel.implicitWidth + 16
                height: 24
                radius: 12
                color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.06)
                border.width: active ? 1 : 0
                border.color: Theme.accent

                Text {
                    id: modeLabel
                    anchors.centerIn: parent
                    text: modeBtn.modelData.label
                    font.pixelSize: 11
                    color: Theme.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.changed("mode", modeBtn.modelData.key)
                }
            }
        }
    }

    Column {
        width: root.width
        spacing: 6
        visible: root.theme.mode === "custom"

        Repeater {
            model: [
                { key: "surface", label: "Hintergrund" },
                { key: "foreground", label: "Text" },
                { key: "accent", label: "Akzent" }
            ]
            delegate: Row {
                id: colorRow
                required property var modelData
                width: colorRow.parent ? colorRow.parent.width : 200
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 6
                    color: root.theme[colorRow.modelData.key] || "#000000"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.25)
                }

                TextField {
                    anchors.verticalCenter: parent.verticalCenter
                    width: colorRow.width - 30
                    text: root.theme[colorRow.modelData.key] || ""
                    placeholder: colorRow.modelData.label + " (#rrggbb)"
                    onEditingFinished: root.changed(colorRow.modelData.key, text)
                }
            }
        }
    }

    Text {
        width: root.width
        visible: root.theme.mode === "adaptive"
        text: "Folgt automatisch dem aktuellen Wallpaper (via shellwall) -- kein Pfad nötig."
        wrapMode: Text.Wrap
        font.pixelSize: 10
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.55)
    }

    LabeledSlider {
        width: root.width
        label: "Deckkraft"
        from: 0.2
        to: 1.0
        value: root.theme.opacity !== undefined ? root.theme.opacity : 0.9
        suffix: "%"
        onMoved: value => root.changed("opacity", value)
    }

    LabeledSlider {
        width: root.width
        label: "Eckenradius"
        from: 0
        to: 24
        value: root.theme.radius !== undefined ? root.theme.radius : 14
        suffix: "px"
        onMoved: value => root.changed("radius", Math.round(value))
    }
}
