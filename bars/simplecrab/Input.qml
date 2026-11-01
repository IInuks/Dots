pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Kapselt JEDE Eingabe-Simulation (Pointer bewegen, klicken, Fenster
// schliessen) hinter dieser einen Schnittstelle, damit das Backend spaeter
// getauscht werden kann (z.B. gegen ein In-Process wlr-virtual-pointer-
// Binding statt eines externen Prozesses), ohne SpiderController oder das
// Overlay anzufassen.
//
// -- Pointer-Bewegung/Klick: wlrctl -----------------------------------
// mango bindet nativ wlr_virtual_pointer_v1 und wlr_foreign_toplevel_
// manager_v1 (gegen den Quellcode geprueft: /nix/store/*-source/src/
// mango.c). wlrctl (nixpkgs: "wlrctl", ~brocellous, reiner Wayland-Client)
// nutzt genau diese Protokolle -- kein ydotoold-Systemdienst, kein
// /dev/uinput noetig wie bei ydotool.
//
// EHRLICHER VORBEHALT: wlrctl war beim Bauen dieser Datei nicht auf dem
// System installiert, die genaue CLI-Syntax unten ist nach allgemeiner
// wlrctl-Konvention geraten, nicht gegen ein echtes Binary verifiziert.
// Nach der Installation (siehe README, NixOS-Abschnitt) mit `wlrctl --help`
// gegenpruefen -- weicht die Syntax ab, NUR die beiden command-Arrays unten
// anpassen, sonst nichts.
//
// Bewegung laeuft relativ (dx, dy), nicht absolut: SpiderController fuehrt
// die absolute Position ohnehin selbst als Wahrheit (siehe dortiger
// Kommentar), kennt also bei jedem Tick exakt das Delta seit dem letzten
// Sync -- das macht die unsichere Frage "unterstuetzt wlrctl absolute
// Koordinaten und in welchem Bezugssystem" komplett irrelevant, relative
// Bewegung ist der Kernfall jedes wlr-virtual-pointer-Clients.
//
// -- Fenster schliessen: mmsg dispatch killclient ----------------------
// Das IST gegen mangos Quellcode verifiziert (src/dispatch/bind_define.h:
// killclient(arg->tc ?: selmon->sel)) und gegen die echte mmsg --help-
// Ausgabe auf diesem System ("dispatch <func> ... client,<id> ... Beispiel:
// dispatch movewin,10,100 client,4"). Kein wlrctl-Toplevel-Close, kein
// simulierter Schliessen-Keybind als Fallback -- deutlich robuster als
// Pointer-hinbewegen-warten-klicken, weil kein Timing-Rennen mit
// focus-follows-mouse noetig ist.
QtObject {
    id: root

    function moveRelative(dx, dy) {
        if (dx === 0 && dy === 0)
            return;
        if (Settings.spiderDebugLatency) {
            // TEMPORAER (Latenz-Diagnose, siehe README/Projektnotizen): misst
            // die Zeit vom Aufruf bis zum Beenden des wlrctl-Prozesses --
            // NICHT bis zum sichtbaren Neuzeichnen des Cursors durch den
            // Compositor, das ist von hier aus nicht messbar. Ein kleiner
            // Wert hier bedeutet: die verbleibende Verzoegerung liegt
            // stromabwaerts (Compositor/Treiber), nicht am Prozess-Spawn.
            const sentAt = Date.now();
            const proc = _debugMoveComponent.createObject(root, {
                command: ["wlrctl", "pointer", "move", String(Math.round(dx)), String(Math.round(dy))],
                sentAt: sentAt
            });
            proc.running = true;
            return;
        }
        Quickshell.execDetached(["wlrctl", "pointer", "move", String(Math.round(dx)), String(Math.round(dy))]);
    }

    property Component _debugMoveComponent: Component {
        Process {
            property real sentAt: 0
            onExited: {
                console.log("[spider-debug] wlrctl move: " + (Date.now() - sentAt) + "ms bis Prozessende");
                destroy();
            }
        }
    }

    function click() {
        Quickshell.execDetached(["wlrctl", "pointer", "click", "left"]);
    }

    // Sucht per "mmsg get all-clients" das Fenster unter (x, y) (in
    // absoluten Compositor-Koordinaten, wie SpiderController sie fuehrt)
    // und schliesst es per killclient. Liegt kein Client an dem Punkt
    // (Desktop, eigene Bar/Menue/Overlay -- Layer-Surfaces tauchen in
    // all-clients gar nicht auf, nur echte Toplevel-Clients), passiert
    // nichts.
    //
    // all-clients liefert keine explizite Stapelreihenfolge (kein z-Index-
    // Feld). Bei ueberlappenden Fenstern wird der aktuell fokussierte
    // Treffer bevorzugt, sonst der erste Treffer der Liste -- das ist ein
    // Best-Effort-Heuristik-Punkt, kein verifiziertes Verhalten. Waehlt es
    // beim Ueberlappen zuverlaessig das falsche Fenster, bitte melden.
    property real _pendingX: 0
    property real _pendingY: 0
    property bool _queryQueued: false

    function closeAt(x, y) {
        root._pendingX = x;
        root._pendingY = y;
        if (root._queryProc.running) {
            // Sehr seltener Fall (Enter zweimal schneller als der lokale
            // mmsg-Roundtrip gedrueckt): einfach nochmal fragen, sobald der
            // laufende Query fertig ist, statt eine Warteschlange echter
            // Requests zu bauen.
            root._queryQueued = true;
            return;
        }
        root._queryProc.running = true;
    }

    property Process _queryProc: Process {
        id: _queryProc
        command: ["mmsg", "get", "all-clients"]
        stdout: StdioCollector {
            onStreamFinished: root._onClientsQueried(text)
        }
        onExited: {
            if (root._queryQueued) {
                root._queryQueued = false;
                root._queryProc.running = true;
            }
        }
    }

    function _onClientsQueried(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        const clients = (data && data.clients) || [];
        const x = root._pendingX, y = root._pendingY;
        const hits = clients.filter(c => c.is_visible && !c.is_minimized && x >= c.x && x < c.x + c.width && y >= c.y && y < c.y + c.height);
        if (hits.length === 0)
            return;
        const target = hits.find(c => c.is_focused) || hits[0];
        Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + target.id]);
    }
}
