import QtQuick

Text {
    property string output: ""
    readonly property string raw: Mango.title(output)

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: Math.min(implicitWidth, Config.titleMaxWidth)
    elide: Text.ElideRight
    text: raw.length ? raw : "Leerer Gabentisch"
    font.family: Theme.font
    font.pixelSize: Theme.textSize
    font.weight: Font.DemiBold
    font.italic: raw.length === 0
    color: raw.length ? Theme.ink : Theme.inkSoft
}
