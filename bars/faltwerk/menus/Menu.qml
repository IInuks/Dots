import QtQuick
import "../core"

// Basis fuer alle Menues: weiss, ob es offen ist, animiert `progress`
// (0..1) und haengt unter dem Knopf, der es geoeffnet hat. Die Position
// wird beim Oeffnen eingefroren, damit ein schliessendes Menue nicht zum
// naechsten Knopf springt.
Item {
    id: m
    required property string screenName
    property real areaWidth: 1920
    property string menuId
    property int openDuration: Paper.tFold
    property int closeDuration: Math.round(Paper.tFold * 0.7)

    readonly property bool shown: Falt.isOpen(menuId, screenName)
    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: m.shown ? m.openDuration : m.closeDuration
            easing.type: m.shown ? Easing.OutCubic : Easing.InCubic
        }
    }

    visible: progress > 0.001
    y: Paper.barZone + 2

    property real anchorX: -1
    onShownChanged: if (shown) anchorX = Falt.anchorX
    x: anchorX < 0 ? (areaWidth - width) / 2 : Math.max(12, Math.min(areaWidth - width - 12, anchorX - width / 2))

    // Klicks im Menue nicht zum "daneben geklickt"-Catcher durchlassen
    MouseArea {
        z: -1
        anchors.fill: parent
        enabled: m.shown
    }
}
