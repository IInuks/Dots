import QtQuick

Text {
    property real size: 13
    property bool bold: false
    font.family: Theme.font
    font.pixelSize: size
    font.weight: bold ? Font.DemiBold : Font.Normal
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
