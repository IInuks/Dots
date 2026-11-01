import QtQuick
import ".."

// Shape/size controls for one island (left/center/right), talking to
// CustomBarsStore.configFile.adapter.islands directly -- same
// read-the-shared-adapter-straight approach as ZoneEditor.qml. Only shown
// by BarEditor when adapter.style === "islands"; dx/dy (position) aren't
// edited here at all -- those come from dragging the chip in BarPreview,
// this only offers a reset back to the default (0,0) position.
Column {
    id: root

    required property string zoneKey
    required property string label

    readonly property var cfg: (CustomBarsStore.configFile.adapter.islands && CustomBarsStore.configFile.adapter.islands[zoneKey]) || {}
    readonly property string shape: cfg.shape || "rounded"
    readonly property real islandHeight: cfg.height || 34
    readonly property real padding: cfg.padding !== undefined ? cfg.padding : 10
    readonly property real explicitWidth: cfg.width || 0
    readonly property real angle: cfg.angle || 0
    readonly property bool moved: (cfg.dx || 0) !== 0

    function update(key, value) {
        const islands = Object.assign({}, CustomBarsStore.configFile.adapter.islands);
        islands[zoneKey] = Object.assign({}, islands[zoneKey], { [key]: value });
        CustomBarsStore.configFile.adapter.islands = islands;
    }

    readonly property var _shapes: [
        { key: "rounded", label: "Rund" },
        { key: "pill", label: "Pille" },
        { key: "square", label: "Eckig" }
    ]

    width: parent ? parent.width : 380
    spacing: 6

    Text {
        text: root.label
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.6)
        font.pixelSize: 11
        font.bold: true
    }

    Row {
        spacing: 6
        Repeater {
            model: root._shapes
            delegate: Rectangle {
                id: shapeBtn
                required property var modelData
                readonly property bool active: root.shape === modelData.key
                width: shapeLabel.implicitWidth + 16
                height: 24
                radius: 12
                color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.06)
                border.width: active ? 1 : 0
                border.color: Theme.accent

                Text { id: shapeLabel; anchors.centerIn: parent; text: shapeBtn.modelData.label; font.pixelSize: 11; color: Theme.foreground }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.update("shape", shapeBtn.modelData.key) }
            }
        }
    }

    LabeledSlider {
        width: root.width
        label: "Höhe"
        from: 24
        to: 48
        value: root.islandHeight
        suffix: "px"
        onMoved: value => root.update("height", Math.round(value))
    }

    LabeledSlider {
        width: root.width
        label: "Innenabstand"
        from: 4
        to: 24
        value: root.padding
        suffix: "px"
        onMoved: value => root.update("padding", Math.round(value))
    }

    LabeledSlider {
        width: root.width
        label: "Breite (0 = automatisch, am Inhalt)"
        from: 0
        to: 200
        value: root.explicitWidth
        suffix: "px"
        onMoved: value => root.update("width", Math.round(value))
    }

    LabeledSlider {
        width: root.width
        label: "Winkel"
        from: -30
        to: 30
        value: root.angle
        suffix: "°"
        onMoved: value => root.update("angle", Math.round(value))
    }

    Text {
        visible: root.moved
        text: "Position zurücksetzen"
        color: Theme.accent
        font.pixelSize: 11
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.update("dx", 0)
        }
    }
}
