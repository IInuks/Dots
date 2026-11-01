import QtQuick

Column {
    id: root
    readonly property var s: Surprises.current
    readonly property var look: Theme.paper(Surprises.paper)

    width: parent ? parent.width : 340
    spacing: 12

    Row {
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.s.icon
            font.family: Theme.icons
            font.pixelSize: 15
            color: root.look.paper
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.s.label.toUpperCase()
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.6
            color: Theme.inkSoft
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.s.text
        font.family: Theme.font
        font.pixelSize: 18
        font.weight: Font.DemiBold
        lineHeight: 1.12
        color: Theme.ink
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.tissueEdge
    }

    Item {
        width: parent.width
        height: 16
        Text {
            anchors.left: parent.left
            text: Theme.iStar + "  Geschenk Nr. " + Surprises.collected + " in deiner Sammlung"
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.inkSoft
        }
        Text {
            anchors.right: parent.right
            text: "Morgen gibt's ein neues."
            font.family: Theme.font
            font.pixelSize: 11
            font.italic: true
            color: Theme.inkSoft
        }
    }
}
