import QtQuick
import qs

// Schwebende Insel in der Leiste
Rectangle {
    implicitHeight: 38
    radius: height / 2
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline
    // aus, wenn der Inhalt seine Breite selbst animiert (sonst hinkt die Insel hinterher)
    property bool animateWidth: true
    Behavior on implicitWidth {
        enabled: animateWidth
        NumberAnimation { duration: Theme.dur(420); easing.type: Easing.OutCubic }
    }
}
