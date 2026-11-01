import QtQuick
import Quickshell
import Quickshell.Io
import "Modules/Bar"
import "Modules/Launcher"

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

    function _launcherScreen() {
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
            screen: shellRoot._launcherScreen()
            onDismissed: shellRoot.launcherOpen = false
        }
    }
}
