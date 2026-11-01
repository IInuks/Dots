import QtQuick

// Ein Nerd-Font-Symbol per Name aus Icons.qml.
Text {
    property string name: ""
    property real size: 16
    text: Icons[name] || ""
    font.family: Theme.icons
    font.pixelSize: size
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
