import QtQuick
import qs

Text {
    property real size: 16
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    Behavior on color { ColorAnimation { duration: Theme.dur(250) } }
}
