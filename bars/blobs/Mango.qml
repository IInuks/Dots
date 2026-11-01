pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango-IPC (mmsg) an einer Stelle. Reales Kommando (mango 0.16.1, siehe
// README "Abweichungen vom Ursprungs-Prompt"): `mmsg watch all-monitors`
// streamt ein JSON-Objekt pro Zeile, sobald sich irgendetwas an irgendeinem
// Monitor aendert -- inklusive einer sofortigen ersten Zeile beim Start, die
// bereits den aktuellen Zustand traegt (kein separater `get`-Aufruf noetig).
// Root-level Singleton wie Theme.qml, aus demselben Cross-Dir-Import-Grund.
QtObject {
    id: root

    // [{name, tags:[{index,is_active,is_urgent,client_count}],
    //   active_tags:[...], ...}, ...]
    property var monitors: []

    function monitorFor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }

    // 0, solange noch keine Daten da sind (WorkspaceBlob zeigt dafuer "-").
    function activeTagFor(screenName) {
        const m = root.monitorFor(screenName);
        return (m && m.active_tags && m.active_tags.length > 0) ? m.active_tags[0] : 0;
    }

    // Welcher Monitor gerade Eingabefokus hat (mmsg's eigenes "active" pro
    // Monitor) -- routet den globalen Launcher-Hotkey an genau die eine
    // Bar-Instanz, auf die der Nutzer gerade schaut, statt ihn auf jedem
    // Screen gleichzeitig zu oeffnen.
    readonly property string focusedMonitorName: {
        const m = root.monitors.find(mon => mon.active);
        return m ? m.name : "";
    }

    property Process _watchProc: Process {
        id: watchProc
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onLine(line)
        }
        // mmsg-Absturz darf die Leiste nicht dauerhaft ohne Tag-Anzeige
        // zurücklassen.
        onExited: _restartTimer.start()
    }
    property Timer _restartTimer: Timer {
        interval: 1000
        onTriggered: {
            watchProc.running = false;
            watchProc.running = true;
        }
    }

    function _onLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.monitors)
            root.monitors = data.monitors;
    }
}
