import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../launcher"

// Unsichtbares Vollbild-Overlay pro Bildschirm. Ist ein Menue offen, faengt
// es Klicks daneben ab (= schliessen) und hat die Tastatur (Esc schliesst).
// Geschlossen ist es per leerer Maske komplett klickdurchlaessig.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name
    readonly property bool active: Falt.menu !== "" && Falt.screenName === screenName

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "faltwerk-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: active ? null : emptyMask
    Region {
        id: emptyMask
        width: 0
        height: 0
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: win.active
        Keys.onEscapePressed: Falt.close()

        // Hintergrund: beim Launcher leicht abgedunkelt
        Rectangle {
            anchors.fill: parent
            color: Paper.dark ? "#000000" : Paper.ink
            opacity: sheetLauncher.progress * (Paper.dark ? 0.5 : 0.35)
        }
        MouseArea {
            anchors.fill: parent
            enabled: win.active
            onClicked: Falt.close()
        }

        CalendarMenu { screenName: win.screenName; areaWidth: win.width }
        SystemMenu { screenName: win.screenName; areaWidth: win.width }
        SoundMenu { screenName: win.screenName; areaWidth: win.width }
        PaperMenu { screenName: win.screenName; areaWidth: win.width }
        NoteMenu { screenName: win.screenName; areaWidth: win.width }
        PowerMenu { screenName: win.screenName; areaWidth: win.width }

        Launcher {
            id: sheetLauncher
            screenName: win.screenName
            areaWidth: win.width
            areaHeight: win.height
        }

        PaperPlane {
            screenName: win.screenName
            anchors.fill: parent
        }
    }
}
