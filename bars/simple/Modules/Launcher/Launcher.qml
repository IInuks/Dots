import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

// Eigenes Overlay-Fenster fuer den Launcher. Wird ueber einen LazyLoader in
// shell.qml jedes Mal frisch erzeugt/zerstoert -- mango gewaehrt einer
// On-Demand-Layer-Surface Keyboard-Fokus nur bei deren allererstem Commit
// (egal ob per Klick oder Hotkey geoeffnet), eine langlebige, wiederver-
// wendete Surface wuerde also nie zuverlaessig Tastatureingaben bekommen.
//
// Fenster spannt bewusst den gesamten Bildschirm auf (transparent), das
// sichtbare Panel sitzt zentriert darin -- ein Klick auf den transparenten
// Rand zaehlt als "ausserhalb" und schliesst den Launcher. Mango kennt
// (anders als Hyprland) keinen Focus-Grab-Mechanismus; diese Technik
// erreicht denselben Effekt rein durch Surface-Groesse + MouseArea.
PanelWindow {
    id: root

    signal dismissed

    property int selectedIndex: 0
    readonly property var results: Apps.list(searchField.text)
    property bool closing: false

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simple-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function requestClose() {
        if (root.closing)
            return;
        root.closing = true;
        content.opacity = 0;
        content.scale = 0.96;
        closeTimer.start();
    }

    function launch(entry) {
        if (!entry)
            return;
        Apps.recordUsage(entry.id);
        entry.execute();
        root.requestClose();
    }

    Timer {
        id: openTimer
        interval: 1
        onTriggered: {
            content.opacity = 1;
            content.scale = 1;
        }
    }

    Timer {
        id: closeTimer
        interval: Settings.launcherAnimationMs
        onTriggered: root.dismissed()
    }

    Component.onCompleted: {
        openTimer.start();
        searchField.focusInput();
    }

    // Klick auf den transparenten Rand ausserhalb des Panels schliesst den
    // Launcher (siehe Datei-Kommentar oben).
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    Rectangle {
        id: content
        anchors.centerIn: parent
        width: Settings.launcherWidth
        height: Settings.launcherHeight
        radius: Settings.launcherRadius
        color: Colors.panel
        opacity: 0
        scale: 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.launcherAnimationMs
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Settings.launcherAnimationMs
                easing.type: Easing.OutCubic
            }
        }

        // Absorbiert Klicks auf den Panel-Hintergrund, damit sie nicht als
        // "Klick ausserhalb" bei der Vollbild-MouseArea darunter zaehlen.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors.fill: parent

            SearchField {
                id: searchField
                width: parent.width
                onTextChanged: root.selectedIndex = 0
                onNavigateUp: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                onNavigateDown: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
                onActivateSelected: root.launch(root.results[root.selectedIndex])
                onCancelled: root.requestClose()
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.divider
            }

            AppList {
                width: parent.width
                height: parent.height - searchField.height - 1
                results: root.results
                selectedIndex: root.selectedIndex
                onActivated: index => root.launch(root.results[index])
            }
        }
    }
}
