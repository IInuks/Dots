import QtQuick
import Quickshell
import Quickshell.Io
import "Modules/Bar"
import "Modules/Launcher"
import "Modules/Spider"

// Root-Datei: Bar pro Bildschirm, Launcher on-demand per LazyLoader (siehe
// Launcher.qml, warum jedes Oeffnen eine frische Surface braucht).
// Colors.qml/Settings.qml/Apps.qml/MangoIpc.qml liegen im selben
// Verzeichnis wie diese Datei und brauchen daher keinen Import (impliziter
// Same-Directory-Zugriff).
//
// SUPER+Space wird NICHT hier im Quickshell-Prozess registriert (mango hat
// kein GlobalShortcut-Protokoll wie Hyprland) -- stattdessen bindet mangos
// eigene Config den Hotkey auf einen externen IPC-Aufruf, siehe README /
// quickdots/menu/adapters/simple.json:
//   bind=SUPER,space,spawn,qs -p ~/quickdots/bars/simple ipc call launcher toggle
ShellRoot {
    id: shellRoot

    property bool launcherOpen: false

    // Wird sowohl vom Launcher als auch vom Spinnen-Overlay genutzt: beide
    // sollen auf dem Bildschirm erscheinen, den der Nutzer gerade ansieht,
    // nicht zwingend auf "Bildschirm 0".
    function _focusedScreen() {
        const monitorName = MangoIpc.focusedMonitorName;
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === monitorName)
                return screens[i];
        }
        return screens.length > 0 ? screens[0] : null;
    }

    // Aufrufbar per
    //   qs -p ~/quickdots/bars/simple ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            shellRoot.launcherOpen = !shellRoot.launcherOpen;
        }
        function open(): void {
            shellRoot.launcherOpen = true;
        }
        function close(): void {
            shellRoot.launcherOpen = false;
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    LazyLoader {
        active: shellRoot.launcherOpen

        Launcher {
            screen: shellRoot._focusedScreen()
            onDismissed: shellRoot.launcherOpen = false
        }
    }

    // Existiert nur, solange der Spinnen-Modus an ist -- siehe
    // SpiderOverlay.qml, warum das fuer den exklusiven Tastaturfokus
    // zwingend ist (nicht nur ein Umschalten auf einem Dauerfenster).
    // Bewusst auf den Bildschirm begrenzt, auf dem der Modus eingeschaltet
    // wurde (siehe README, "Bekannte Luecken" -- Bewegung ueber
    // Bildschirmgrenzen hinweg ist nicht implementiert).
    LazyLoader {
        active: SpiderState.enabled

        SpiderOverlay {
            screen: shellRoot._focusedScreen()
        }
    }
}
