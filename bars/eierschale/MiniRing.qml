import QtQuick

// Kleiner Ring mit Symbol in der Mitte (CPU/RAM in der Leiste).
Item {
    property real value: 0
    property string icon: ""
    property color tint: Theme.accent
    width: 24; height: 24
    Ring {
        anchors.fill: parent
        value: parent.value
        thickness: 3
        tint: parent.value > 0.85 ? Theme.bad : parent.tint
    }
    Icon { anchors.centerIn: parent; name: parent.icon; size: 11; color: Theme.textDim }
}
