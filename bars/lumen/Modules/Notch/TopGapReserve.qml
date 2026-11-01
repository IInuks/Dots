import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

// Reserviert oben eine schmale Zone per exclusiveZone, damit getilte Fenster
// unterhalb der kollabierten Pille beginnen statt direkt darunter/dahinter
// zu liegen -- ohne dieses Fenster liegt exclusiveZone am Notch selbst auf 0
// (siehe dortigen Kommentar) und es gibt ueberhaupt keine reservierte Zone.
//
// Eigenes, unsichtbares, immer klick-durchlaessiges Fenster statt
// exclusiveZone direkt am Notch: mango stapelt mehrere gleich-kantige
// Layer-Shell-Surfaces, indem es jede um die exclusiveZone der jeweils
// ANDEREN verschiebt (bestaetigtes Verhalten, siehe Notch.qml-Kommentar zu
// margins.top) -- eine eigene Reservierungs-Surface auf WlrLayer.Bottom
// (anderer Layer als der Notch auf Overlay) umgeht das fuer den Notch
// selbst, exakt das Muster aus bars/floating/TopGapReserve.qml.
PanelWindow {
    id: reserve

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Settings.notchTopReserveZone

    color: "transparent"
    exclusiveZone: Settings.notchTopReserveZone

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "lumen-topgap"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: emptyRegion
    Region { id: emptyRegion; width: 0; height: 0 }
}
