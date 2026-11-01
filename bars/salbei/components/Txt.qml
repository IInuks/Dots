import QtQuick
import "../"

// Text with the shell font and defaults.
Text {
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontItem
    font.weight: Font.Medium
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
