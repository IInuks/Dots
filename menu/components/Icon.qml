import QtQuick
import ".."

// One Nerd Font glyph (Font Awesome range, e.g. "").
Text {
    property int size: Theme.fontM
    font.family: Theme.monoFamily
    font.pixelSize: size
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
