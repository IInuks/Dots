import QtQuick
import "../"

// One glyph, Material Symbols Rounded if installed, a plain Unicode/ASCII
// fallback otherwise -- so the shell never starts unreadable just because
// pkgs.material-symbols isn't on this system yet (Theme.iconFontAvailable
// checked once via Qt.fontFamilies()).
Text {
    id: root

    property string glyph: "circle" // Material Symbols ligature name
    property string fallback: "•" // shown if the icon font is missing

    text: Theme.iconFontAvailable ? root.glyph : root.fallback
    font.family: Theme.iconFontAvailable ? Theme.iconFontFamily : "sans-serif"
    font.pixelSize: 20
    color: Theme.surfaceVariantInk
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
