import QtQuick
import "../"

// Text in the shell's typeface.
//   role: "body" | "muted" | "title" | "big" | "caps" (tiny spaced caps)
Text {
    property string role: "body"
    color: role === "muted" || role === "caps" ? Theme.textMuted : Theme.text
    font.family: Theme.font
    font.pixelSize: role === "big" ? Theme.fBig : role === "title" ? Theme.fTitle : role === "caps" ? Theme.fTiny : role === "muted" ? Theme.fSmall : Theme.fBody
    font.weight: role === "big" ? Font.Bold : role === "title" ? Font.DemiBold : role === "caps" ? Font.DemiBold : role === "muted" ? Font.Light : Font.Medium
    font.letterSpacing: role === "caps" ? 1.6 : 0
    font.capitalization: role === "caps" ? Font.AllUppercase : Font.MixedCase
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
