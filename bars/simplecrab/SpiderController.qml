pragma Singleton
import QtQuick
import Quickshell.Io

// Haelt die vom Shell selbst verwaltete Zeigerposition + den kompletten
// Bewegungszustand des Spinnen-Modus. Die Shell liest die reale System-
// Zeigerposition NIE zurueck -- x/y hier SIND die Wahrheit, ydotool/wlrctl
// bewegt den echten Pointer nur hinterher (siehe Input.qml). Das funktioniert
// nur, weil ausschliesslich dieser Controller den Pointer bewegt, solange
// der Modus aktiv ist -- fasst der Nutzer waehrenddessen die echte Maus an,
// laufen beide Positionen auseinander (siehe README).
//
// Existiert nur, solange SpiderOverlay.qml existiert (start()/stop() werden
// von dessen Component.onCompleted/onDestruction aufgerufen) -- kein Timer
// tickt je, wenn der Modus aus ist.
QtObject {
    id: root

    property real x: 0
    property real y: 0
    property real heading: 0 // radians, 0 = nach rechts
    property bool moving: false

    property real screenWidth: 0
    property real screenHeight: 0

    // Tastenzustand -- WASD und Pfeiltasten fuettern dieselben vier Flags
    // (siehe SpiderOverlay.qml), ergeben zusammen einen normalisierten
    // Vektor (keine schnelleren Diagonalen).
    property bool keyUp: false
    property bool keyDown: false
    property bool keyLeft: false
    property bool keyRight: false

    // Joystick liefert Richtung UND Auslenkung direkt als -1..1 pro Achse
    // und hat Vorrang vor den Tasten, solange er ausgelenkt ist.
    property real joystickX: 0
    property real joystickY: 0

    function setJoystick(vx, vy) {
        root.joystickX = vx;
        root.joystickY = vy;
    }

    function start(screen) {
        root.screenWidth = screen.width;
        root.screenHeight = screen.height;
        // Bildschirmmitte ist nur ein Platzhalter fuer den einen Frame, bis
        // _onCursorQueried() unten die Figur an die tatsaechliche Position
        // des echten Zeigers springen laesst -- ohne das wuerde die Figur
        // dauerhaft versetzt zum echten Mauszeiger laufen (der Zeiger bewegt
        // sich ja nur relativ, siehe Input.qml, gleicht also nie von selbst
        // auf einen absoluten Startpunkt ab).
        root.x = screen.width / 2;
        root.y = screen.height / 2;
        root._pendingDx = 0;
        root._pendingDy = 0;
        root._tickCounter = 0;
        root._lastTickTime = Date.now();
        root.moving = false;
        _tick.restart();
        root._cursorQueryProc.running = true;
    }

    // Einmaliger Abgleich beim Einschalten: liest die echte Zeigerposition
    // per mmsg (Feld existiert extra dafuer, "get cursorpos") und setzt die
    // intern gefuehrte Position direkt darauf -- kein wlrctl-Move noetig,
    // der echte Zeiger steht ja bereits dort. _pendingDx/_pendingDy werden
    // mitzurueckgesetzt, damit der naechste Tick nicht faelschlich einen
    // riesigen Sprung (Bildschirmmitte -> echte Position) an wlrctl schickt.
    property Process _cursorQueryProc: Process {
        command: ["mmsg", "get", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: root._onCursorQueried(text)
        }
    }

    function _onCursorQueried(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return; // Bildschirmmitte aus start() bleibt der Fallback.
        }
        if (typeof data.x !== "number" || typeof data.y !== "number")
            return;
        root.x = Math.max(0, Math.min(root.screenWidth, data.x));
        root.y = Math.max(0, Math.min(root.screenHeight, data.y));
        root._pendingDx = 0;
        root._pendingDy = 0;
    }

    function stop() {
        _tick.stop();
        root.keyUp = root.keyDown = root.keyLeft = root.keyRight = false;
        root.joystickX = 0;
        root.joystickY = 0;
        root.moving = false;
    }

    // Linksklick an der aktuellen Position: der echte Pointer muss dafuer
    // erst aufgeholt haben (siehe spiderPointerSyncEveryNTicks), sonst
    // klickt der reale Zeiger noch an einer leicht veralteten Stelle.
    function pressClick() {
        root._flushPointer();
        Input.click();
    }

    // Schliessen nutzt die intern gefuehrte Position direkt (siehe
    // Input.closeAt) -- braucht den aufgeholten echten Pointer nicht.
    function closeUnderneath() {
        Input.closeAt(root.x, root.y);
    }

    property real _lastTickTime: 0
    property real _pendingDx: 0
    property real _pendingDy: 0
    property int _tickCounter: 0

    property Timer _tick: Timer {
        interval: Settings.spiderTickMs
        repeat: true
        onTriggered: root._step()
    }

    function _step() {
        const now = Date.now();
        if (Settings.spiderDebugLatency) {
            // TEMPORAER (Latenz-Diagnose) -- zeigt, ob der Timer selbst
            // schon hinter seinem Soll-Intervall (Settings.spiderTickMs)
            // zurueckbleibt, unabhaengig von wlrctl.
            const drift = (now - root._lastTickTime) - Settings.spiderTickMs;
            console.log("[spider-debug] tick sinceLast=" + (now - root._lastTickTime) + "ms drift=" + drift + "ms");
        }
        // Deckel gegen Ausreisser nach einem Ruckler/Suspend -- ohne den
        // wuerde ein einzelner sehr grosser dt die Figur ueber den ganzen
        // Bildschirm springen lassen statt sauber weiterzulaufen.
        const dt = Math.min((now - root._lastTickTime) / 1000, 0.1);
        root._lastTickTime = now;

        let vx = 0, vy = 0;
        const joyMag = Math.hypot(root.joystickX, root.joystickY);
        if (joyMag > 0.05) {
            const mag = Math.min(joyMag, 1);
            vx = (root.joystickX / joyMag) * mag;
            vy = (root.joystickY / joyMag) * mag;
        } else {
            const kx = (root.keyRight ? 1 : 0) - (root.keyLeft ? 1 : 0);
            const ky = (root.keyDown ? 1 : 0) - (root.keyUp ? 1 : 0);
            if (kx !== 0 || ky !== 0) {
                const len = Math.hypot(kx, ky);
                vx = kx / len;
                vy = ky / len;
            }
        }

        const speed = SpiderState.speed;
        const dx = vx * speed * dt;
        const dy = vy * speed * dt;

        root.moving = dx !== 0 || dy !== 0;
        if (root.moving)
            root.heading = Math.atan2(vy, vx);

        const nx = Math.max(0, Math.min(root.screenWidth, root.x + dx));
        const ny = Math.max(0, Math.min(root.screenHeight, root.y + dy));
        root._pendingDx += nx - root.x;
        root._pendingDy += ny - root.y;
        root.x = nx;
        root.y = ny;

        root._tickCounter++;
        if (root._tickCounter % Settings.spiderPointerSyncEveryNTicks === 0)
            root._flushPointer();
    }

    function _flushPointer() {
        if (root._pendingDx !== 0 || root._pendingDy !== 0) {
            Input.moveRelative(root._pendingDx, root._pendingDy);
            root._pendingDx = 0;
            root._pendingDy = 0;
        }
    }
}
