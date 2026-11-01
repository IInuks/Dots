import QtQuick

// Small round prev/next control used in CalendarPopup.
Rectangle {
    id: nav
    property string symbol: ""
    signal clicked()

    width: 24
    height: 24
    radius: 12
    color: navMouse.containsMouse ? Qt.alpha(Theme.foreground, 0.10) : "transparent"

    Text { anchors.centerIn: parent; text: nav.symbol; color: Theme.foreground; font.pixelSize: Theme.fontSizeNormal }
    MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav.clicked() }
}
