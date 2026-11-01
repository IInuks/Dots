import QtQuick
import ".."

Item {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        text: Math.round(SysStats.usage) + "%"
    }
}
