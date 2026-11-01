import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Modules/Notch"

// Root-Datei: pro Bildschirm EIN schwebender Notch (siehe
// Modules/Notch/Notch.qml), der sich selbst zwischen Pille/Settings-Karte/
// Suche/Wallpaper-Grid VERFORMT -- kein separates Launcher- oder
// WallpaperPicker-Fenster mehr, das waere wieder "ein eigenes Menue mit
// Gap" gewesen. Colors.qml/Settings.qml/MangoIpc.qml/Apps.qml/
// Wallpaper.qml liegen im selben Verzeichnis wie diese Datei und brauchen
// daher keinen Import (impliziter Same-Directory-Zugriff).
//
// SUPER+Space wird NICHT hier im Quickshell-Prozess registriert (mango hat
// kein GlobalShortcut-Protokoll wie Hyprland) -- stattdessen bindet mangos
// eigene Config den Hotkey auf einen externen IPC-Aufruf, siehe README /
// quickdots/menu/adapters/lumen.json:
//   bind=SUPER,space,spawn,qs -p ~/quickdots/bars/lumen ipc call launcher toggle
ShellRoot {
    id: shellRoot

    // Geteilter Zustand, den jeder Notch (einer pro Bildschirm) liest, um
    // zu entscheiden, ob/wie er sich verformt (siehe Notch.qml:
    // expanded/subview). "" | "search" | "wallpaper".
    property bool menuOpen: false
    property string menuSubview: ""

    // Aufrufbar per
    //   qs -p ~/quickdots/bars/lumen ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (shellRoot.menuOpen && shellRoot.menuSubview === "search") {
                shellRoot.menuOpen = false;
            } else {
                shellRoot.menuOpen = true;
                shellRoot.menuSubview = "search";
            }
        }
        function open(): void {
            shellRoot.menuOpen = true;
            shellRoot.menuSubview = "search";
        }
        function close(): void {
            shellRoot.menuOpen = false;
        }
    }

    // Aufrufbar per
    //   qs -p ~/quickdots/bars/lumen ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (shellRoot.menuOpen && shellRoot.menuSubview === "wallpaper") {
                shellRoot.menuOpen = false;
            } else {
                shellRoot.menuOpen = true;
                shellRoot.menuSubview = "wallpaper";
            }
        }
        function open(): void {
            shellRoot.menuOpen = true;
            shellRoot.menuSubview = "wallpaper";
        }
        function close(): void {
            shellRoot.menuOpen = false;
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: TopGapReserve {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Notch {
            appRoot: shellRoot
        }
    }

    // Klick-ausserhalb-schliesst, waehrend der Notch "angepinnt" (per Klick
    // auf einen Schnellzugriff-Chip oder per IPC) in der Suche/dem
    // Wallpaper-Grid steht -- reine Hover-Vorschau (Settings-Karte)
    // schliesst dagegen schon durch Hover-Exit im Notch selbst, siehe
    // dortigen Kommentar. Ein separates, permanent klick-durchlaessiges
    // Vollbild-Fenster statt exclusiveZone am Notch selbst -- gleiche
    // Technik wie bars/floating/shell.qml. WlrLayer.Top hier, Overlay beim
    // Notch: Overlay stapelt garantiert ueber Top, sonst wuerde dieser
    // Catcher Klicks auf den Notch selbst als "ausserhalb" abfangen statt
    // sie durchzulassen.
    PanelWindow {
        id: catcher
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "lumen-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: shellRoot.menuOpen ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        MouseArea {
            anchors.fill: parent
            enabled: shellRoot.menuOpen
            onClicked: shellRoot.menuOpen = false
        }
    }
}
