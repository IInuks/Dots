import QtQuick
import "../"

// "Label ........ [control]" row used throughout the Studio.
Item {
    id: root
    property string label
    property string sub: ""
    default property alias control: slot.data

    implicitHeight: Math.max(36, texts.implicitHeight + 6)
    implicitWidth: 360

    Column {
        id: texts
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - slot.width - Theme.s3
        KLabel { width: parent.width; text: root.label }
        KLabel { width: parent.width; role: "muted"; text: root.sub; visible: text !== "" }
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
