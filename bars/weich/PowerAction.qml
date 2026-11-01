import QtQuick

// Round icon button used in the SettingsPopup power row; `confirming`
// highlights it while a destructive action is waiting for a second click.
Rectangle {
    id: action
    property string symbol: ""
    property bool confirming: false
    signal triggered()

    width: 34
    height: 34
    radius: 17
    color: confirming ? Qt.alpha(Theme.accent, 0.35) : (mouse.containsMouse ? Qt.alpha(Theme.foreground, 0.10) : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text { anchors.centerIn: parent; text: action.symbol; font.pixelSize: Theme.fontSizeNormal }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: action.triggered()
    }
}
