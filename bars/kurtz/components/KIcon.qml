import QtQuick
import "../"

// A single filled glyph from Glyphs.qml.
Text {
    property real size: 16
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
