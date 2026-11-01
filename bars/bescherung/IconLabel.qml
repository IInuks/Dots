import QtQuick

// Ein einzelnes Symbol als Inhalt eines Geschenks (Launcher, Power, ...).
Text {
    property color tint: Theme.ink
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    font.family: Theme.icons
    font.pixelSize: 15
    color: tint
    horizontalAlignment: Text.AlignHCenter
}
