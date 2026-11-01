import QtQuick
import "../.."

// App-Liste: nur Namen, Zeilenhoehe/Innenabstand aus Settings, selektierter
// Eintrag hervorgehoben.
ListView {
    id: root

    required property var results
    required property int selectedIndex
    signal activated(int index)

    clip: true
    model: results
    currentIndex: selectedIndex
    highlightFollowsCurrentItem: true
    onSelectedIndexChanged: positionViewAtIndex(selectedIndex, ListView.Contain)

    delegate: Item {
        id: delegateRoot

        required property var modelData
        required property int index

        width: root.width
        height: Settings.searchRowHeight

        Rectangle {
            visible: delegateRoot.index === root.selectedIndex
            anchors.fill: parent
            anchors.margins: 4
            radius: 6
            color: Colors.accent
        }

        Text {
            text: delegateRoot.modelData.name
            anchors.left: parent.left
            anchors.leftMargin: Settings.searchRowPadding
            anchors.verticalCenter: parent.verticalCenter
            font.family: Colors.fontFamily
            font.pointSize: Colors.fontSize
            font.letterSpacing: Colors.letterSpacing
            color: delegateRoot.index === root.selectedIndex ? Colors.accentInk : Colors.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated(delegateRoot.index)
        }
    }
}
