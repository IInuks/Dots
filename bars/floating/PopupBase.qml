import QtQuick

// Shared popup chrome: same island look (background/border/radius) as the
// bar itself (spec 4, "Gleicher Island-Stil wie die Bar"). Opens instantly,
// no fade/slide -- an earlier version animated this in, but any animation
// here read as the same unwanted "things move when you click" effect the
// island-position bug caused (see IslandBase.qml), so it was removed
// entirely rather than just fixing the real bug and leaving this in.
Rectangle {
    id: root

    property real popupWidth: 260
    property real popupHeight: 200
    default property alias content: contentArea.data

    implicitWidth: popupWidth
    implicitHeight: popupHeight

    color: Theme.islandBackgroundColor
    radius: Theme.islandRadius
    border.width: Theme.islandBorderWidth
    border.color: Theme.islandBorderColor

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: 10
    }
}
