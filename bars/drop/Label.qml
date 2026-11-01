import QtQuick

Text {
    property real size: 13
    property bool bold: false
    property bool rounded: false
    font.family: rounded ? Theme.round : Theme.font
    font.pixelSize: size
    font.weight: bold ? (rounded ? Font.Bold : Font.DemiBold) : (rounded ? Font.Medium : Font.Normal)
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
