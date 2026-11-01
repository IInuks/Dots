import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 13
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    Behavior on color { ColorAnimation { duration: Theme.dur(250) } }
}
