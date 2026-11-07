import QtQuick

// Eigene deltaTime-basierte Integration (Auftrag: "eigene Integration in
// einer FrameAnimation ... delta-time-basiert, nicht frame-count-basiert").
// Kennt nur Zahlen (Position, Geschwindigkeit, Grenzen) -- keine Ahnung von
// Fenstern/Layer-Shell, damit es unabhaengig testbar bleibt.
QtObject {
    id: root

    // Position des Blob-Mittelpunkts, in Fenster-/Bildschirm-Pixeln.
    property real posX: 0
    property real posY: 0
    property real vx: 0
    property real vy: 0

    property real radius: 60
    property real boundsWidth: 0
    property real boundsHeight: 0
    // Zusaetzlicher Freiraum am oberen Rand, den der Blob weder beim
    // Abprallen (step()) noch beim Ecken-Anflug (flyToCorner()) noch beim
    // Ziehen (_clampY) betritt -- damit er nicht unter eine dort sitzende
    // Bar rutscht (siehe Settings.barMargin).
    property real topMargin: 0

    property real restitution: 0.8
    property bool gravityEnabled: false
    property real gravityAccel: 2200 // px/s^2
    // Linearer Luftwiderstand: Anteil der Geschwindigkeit, der pro Sekunde
    // erhalten bleibt (0.999 = kaum Bremsung, 0.9 = spuerbare Bremsung).
    property real airFriction: 0.996
    // Unterhalb dieser Geschwindigkeit (px/s) gilt der Blob als "zur Ruhe
    // gekommen" -- verhindert ewiges Mikro-Zittern kurz vorm Stillstand.
    property real restThreshold: 14

    // Sanftes Hinausgleiten in die naechste Bildschirmecke, wenn der Blob
    // laenger nicht bewegt wurde (siehe BlobWindow.qml, Idle-Timer). Bewusst
    // getrennt vom Wurf/Abprall-Modell in step(): eine mit realistischer
    // elastischer Kollision geworfene Kugel landet nicht zuverlaessig exakt
    // in einer Ecke, ein direktes Exponential-Ease-Out dagegen schon.
    property bool flyingToCorner: false
    property real cornerSeekSpeed: 4.0 // groesser = schnelleres Einschwenken
    property real _cornerTargetX: 0
    property real _cornerTargetY: 0

    // "nearest" (Standard) waehlt die dem Blob gerade am naechsten liegende
    // Ecke; alternativ eine fest gewaehlte Ecke ("topLeft"/"topRight"/
    // "bottomLeft"/"bottomRight").
    property string preferredCorner: "nearest"

    signal arrivedAtCorner()

    // In der Ecke geparkt (nach stepToCorner angekommen): bleibt liegen, bis
    // er gegriffen oder geschleudert wird -- auch mit Schwerkraft. Sonst
    // fiel er aus einer oberen Ecke sofort wieder runter, kam unten zur
    // Ruhe, flog wieder hoch usw.
    property bool parked: false

    function flyToCorner() {
        if (root.dragging || root.slingshotActive) return;
        switch (root.preferredCorner) {
        case "topLeft":
            root._cornerTargetX = root.radius;
            root._cornerTargetY = root.radius + root.topMargin;
            break;
        case "topRight":
            root._cornerTargetX = root.boundsWidth - root.radius;
            root._cornerTargetY = root.radius + root.topMargin;
            break;
        case "bottomLeft":
            root._cornerTargetX = root.radius;
            root._cornerTargetY = root.boundsHeight - root.radius;
            break;
        case "bottomRight":
            root._cornerTargetX = root.boundsWidth - root.radius;
            root._cornerTargetY = root.boundsHeight - root.radius;
            break;
        default:
            root._cornerTargetX = root.posX < root.boundsWidth / 2 ? root.radius : root.boundsWidth - root.radius;
            root._cornerTargetY = root.posY < root.boundsHeight / 2 ? root.radius + root.topMargin : root.boundsHeight - root.radius;
        }
        root.parked = false;
        root.flyingToCorner = true;
    }

    function cancelFlight() {
        root.flyingToCorner = false;
    }

    function stepToCorner(dt) {
        if (dt <= 0 || dt > 0.25) return;

        const k = 1 - Math.exp(-root.cornerSeekSpeed * dt);
        root.posX += (root._cornerTargetX - root.posX) * k;
        root.posY += (root._cornerTargetY - root.posY) * k;

        const dx = root._cornerTargetX - root.posX;
        const dy = root._cornerTargetY - root.posY;
        if (Math.hypot(dx, dy) < 0.75) {
            root.posX = root._cornerTargetX;
            root.posY = root._cornerTargetY;
            root.vx = 0;
            root.vy = 0;
            root.flyingToCorner = false;
            root.parked = true;
            root.arrivedAtCorner();
        }
    }

    property bool dragging: false

    // Steinschleuder: rechte Maustaste haelt den Blob an seiner aktuellen
    // Position fest (Anker), Ziehen verschiebt ihn nur visuell (geclampt auf
    // maxSlingshotPull), Loslassen schiesst ihn mit einer Geschwindigkeit
    // proportional zum Zug-Vektor in die ENTGEGENGESETZTE Richtung ab (wie
    // beim Zwille-Spannen) und uebergibt danach an die normale step()-Wurf-
    // physik (Abprall/Restitution gelten fuer den Schuss genauso wie fuer
    // einen normalen Wurf).
    property bool slingshotActive: false
    property real slingshotAnchorX: 0
    property real slingshotAnchorY: 0
    property real slingshotPullX: 0
    property real slingshotPullY: 0
    property real maxSlingshotPull: 220 // px, Zug-Radius-Deckel
    property real slingshotPower: 6.0 // Zug-Distanz * Power = Abschussgeschwindigkeit

    function beginSlingshot(px, py) {
        root.dragging = false;
        root.flyingToCorner = false;
        root.parked = false;
        root.slingshotActive = true;
        root.vx = 0;
        root.vy = 0;
        root.slingshotAnchorX = root.posX;
        root.slingshotAnchorY = root.posY;
        root.slingshotPullX = 0;
        root.slingshotPullY = 0;
    }

    function updateSlingshot(px, py) {
        if (!root.slingshotActive) return;
        let dx = px - root.slingshotAnchorX;
        let dy = py - root.slingshotAnchorY;
        const dist = Math.hypot(dx, dy);
        if (dist > root.maxSlingshotPull) {
            const s = root.maxSlingshotPull / dist;
            dx *= s;
            dy *= s;
        }
        root.slingshotPullX = dx;
        root.slingshotPullY = dy;
        root.posX = root._clampX(root.slingshotAnchorX + dx);
        root.posY = root._clampY(root.slingshotAnchorY + dy);
    }

    function endSlingshot() {
        if (!root.slingshotActive) return;
        root.slingshotActive = false;
        root.vx = -root.slingshotPullX * root.slingshotPower;
        root.vy = -root.slingshotPullY * root.slingshotPower;
        root.posX = root.slingshotAnchorX;
        root.posY = root.slingshotAnchorY;
        root.slingshotPullX = 0;
        root.slingshotPullY = 0;
    }

    // Mit aktiver Schwerkraft "ruht" der Blob, sobald er auf dem Boden
    // aufliegt UND langsam genug ist -- sonst wuerde atRest nie eintreten
    // (Schwerkraft zieht ihn ja staendig weiter) und step() wuerde ewig in
    // winzigen Mikro-Abprallern am Boden weiterzittern.
    readonly property bool _onFloor: Math.abs(root.posY - (root.boundsHeight - root.radius)) < 0.5
    readonly property bool atRest: !root.dragging
        && !root.slingshotActive
        && !root.flyingToCorner
        && Math.abs(root.vx) < root.restThreshold
        && Math.abs(root.vy) < root.restThreshold
        && (!root.gravityEnabled || root._onFloor || root.parked)

    signal bounced(string edge)

    // Ring-Puffer der letzten Mausposition/Zeitpunkte waehrend eines Drags,
    // um beim Loslassen eine natuerliche Wurfgeschwindigkeit aus den letzten
    // ~5 Samples zu mitteln statt aus nur den letzten zwei (die bei 60Hz
    // Mausevents sehr verrauscht sind).
    property var _samples: []
    readonly property int _maxSamples: 5

    function beginDrag(px, py) {
        root.dragging = true;
        root.flyingToCorner = false;
        root.parked = false;
        root.vx = 0;
        root.vy = 0;
        root._samples = [{ t: Date.now(), x: px, y: py }];
        root.posX = px;
        root.posY = py;
    }

    function updateDrag(px, py) {
        if (!root.dragging) return;
        root.posX = root._clampX(px);
        root.posY = root._clampY(py);

        const samples = root._samples;
        samples.push({ t: Date.now(), x: root.posX, y: root.posY });
        while (samples.length > root._maxSamples)
            samples.shift();
        root._samples = samples;
    }

    function endDrag() {
        if (!root.dragging) return;
        root.dragging = false;

        const samples = root._samples;
        if (samples.length >= 2) {
            const first = samples[0];
            const last = samples[samples.length - 1];
            const dt = (last.t - first.t) / 1000;
            if (dt > 0.001) {
                root.vx = (last.x - first.x) / dt;
                root.vy = (last.y - first.y) / dt;
            }
        }
        root._samples = [];
    }

    function _clampX(px) {
        return Math.max(root.radius, Math.min(root.boundsWidth - root.radius, px));
    }
    function _clampY(py) {
        return Math.max(root.radius + root.topMargin, Math.min(root.boundsHeight - root.radius, py));
    }

    // dt in Sekunden, von FrameAnimation.frameTime. Wird von aussen
    // aufgerufen (BlobWindow haelt die FrameAnimation), damit Physics.qml
    // selbst kein QtObject-mit-Timer-Foot-Gun-Kind braucht.
    function step(dt) {
        if (root.dragging || root.slingshotActive) return;
        if (dt <= 0 || dt > 0.25) return; // grosse Ausreisser (Tab-Wechsel etc.) ignorieren

        if (root.gravityEnabled)
            root.vy += root.gravityAccel * dt;

        const decay = Math.pow(root.airFriction, dt * 60);
        root.vx *= decay;
        root.vy *= decay;

        if (root.atRest) {
            root.vx = 0;
            root.vy = 0;
            return;
        }

        let nx = root.posX + root.vx * dt;
        let ny = root.posY + root.vy * dt;

        const minX = root.radius;
        const maxX = root.boundsWidth - root.radius;
        const minY = root.radius + root.topMargin;
        const maxY = root.boundsHeight - root.radius;

        if (nx < minX) {
            nx = minX;
            root.vx = Math.abs(root.vx) * root.restitution;
            root.bounced("left");
        } else if (nx > maxX) {
            nx = maxX;
            root.vx = -Math.abs(root.vx) * root.restitution;
            root.bounced("right");
        }

        if (ny < minY) {
            ny = minY;
            root.vy = Math.abs(root.vy) * root.restitution;
            root.bounced("top");
        } else if (ny > maxY) {
            ny = maxY;
            root.vy = -Math.abs(root.vy) * root.restitution;
            root.bounced("bottom");
        }

        root.posX = nx;
        root.posY = ny;
    }
}
