import QtQuick
import ".."

// Heading + one-line subtitle at the top of a step page.
Column {
    property string title: ""
    property string subtitle: ""
    spacing: 3

    Text {
        text: parent.title
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXl
        font.weight: Font.Bold
    }
    Text {
        visible: text.length > 0
        width: parent.width
        text: parent.subtitle
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontM
        wrapMode: Text.WordWrap
    }
}
