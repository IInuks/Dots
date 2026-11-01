import QtQuick
import "../"

// One glyph, Material Symbols Rounded if installed, a plain Unicode/ASCII
// fallback otherwise -- same pattern as bars/lucid/Bar/Icon.qml, so the
// shell is never unreadable before `material-symbols` lands (see README
// "Nix-Pakete").
Text {
    id: root

    property string glyph: "circle"
    property string fallback: "•"
    property color tint: Theme.text
    property int size: 18

    text: Theme.iconFontAvailable ? root.glyph : root.fallback
    font.family: Theme.iconFontAvailable ? Theme.iconFontFamily : "sans-serif"
    font.pixelSize: root.size
    color: root.tint
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
