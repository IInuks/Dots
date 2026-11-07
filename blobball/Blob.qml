import QtQuick
import QtQuick.Shapes

// Reine Darstellung: Form + alle "lebendig wirkenden" Animationen (Squash &
// Stretch beim Aufprall, Atem-Wobble im Ruhezustand, Wachsen beim Greifen).
// Kennt nichts von Physik/Fenstern -- BlobWindow.qml bindet size/shapeKind/
// dragging von aussen und ruft squash(edge) bei einem Physics.bounced-Signal.
Item {
    id: root

    property real size: 120
    property string shapeKind: "circle" // "circle" | "roundedSquare" | "squircle" | "organic"
    property color blobColor: "#7c5cff"
    property bool dragging: false
    property bool atRest: true

    // Staerke der Verformungen unten (Squash beim Aufprall/bei einer
    // Nachricht, Atem-Wobble, organisches Wabern). 0 = starr, 1 = die
    // urspruenglichen, fest verdrahteten Werte, 2 = stark uebertrieben.
    property real jiggle: 1.0

    // Augen: von aussen (BlobWindow) gesetztes Blickziel, -1..1 relativ zur
    // Erkennungszone um den Blob. lookTracking=false (Maus ausserhalb der
    // Zone) laesst die Augen stattdessen selbststaendig umherschauen -- die
    // "lebendig wirkenden" Idle-Animationen bleiben bewusst hier gekapselt,
    // BlobWindow liefert nur rohe Geometrie (siehe Kommentare oben zu
    // squash/atRest).
    property real targetLookX: 0
    property real targetLookY: 0
    property bool lookTracking: false

    // Steinschleuder-Zug, von aussen (BlobWindow) aus Physics.slingshotPullX/Y
    // gesetzt, je -1..1 relativ zu maxSlingshotPull. Erzeugt einen Gummiband-
    // Stretch entlang der Zugachse -- rein optisch, kennt nichts von Physik.
    property real pullX: 0
    property real pullY: 0
    Behavior on pullX { SpringAnimation { spring: 3.5; damping: 0.4 } }
    Behavior on pullY { SpringAnimation { spring: 3.5; damping: 0.4 } }
    readonly property real _pullMag: Math.min(1, Math.hypot(root.pullX, root.pullY))
    readonly property real _pullAngle: Math.atan2(root.pullY, root.pullX) * 180 / Math.PI

    // Blickrichtung der Pupillen. Keine Behavior/SpringAnimation mehr: die
    // globale Zeigerposition (wirbel pos) kommt alle paar Millisekunden,
    // und jede neue Zielposition hat die Feder neu gestartet -- das wirkte
    // ruckelig. Stattdessen naehert eine FrameAnimation _look einmal pro
    // gezeichnetem Bild exponentiell ans aktuelle Ziel an (bildratenunab-
    // haengig, egal wie viele Zeigerzeilen dazwischen ankamen).
    property real _lookX: 0
    property real _lookY: 0
    property real _wanderX: 0
    property real _wanderY: 0
    readonly property real _goalX: root.lookTracking ? root.targetLookX : root._wanderX
    readonly property real _goalY: root.lookTracking ? root.targetLookY : root._wanderY
    // Zeitkonstante: ~30ms beim Verfolgen (wirkt direkt), beim selbststaendigen
    // Umherschauen gemaechlicher.
    readonly property real _lookRate: root.lookTracking ? 34 : 9

    FrameAnimation {
        running: Math.abs(root._goalX - root._lookX) > 0.0005 || Math.abs(root._goalY - root._lookY) > 0.0005
        onTriggered: {
            const k = 1 - Math.exp(-Math.min(frameTime, 0.05) * root._lookRate);
            root._lookX += (root._goalX - root._lookX) * k;
            root._lookY += (root._goalY - root._lookY) * k;
        }
    }

    Timer {
        // Nur aktiv, solange kein Zeiger verfolgt wird -- waehlt in
        // unregelmaessigen Abstaenden ein neues Blickziel, zu dem die
        // FrameAnimation oben dann hinueberschwenkt.
        running: !root.lookTracking
        repeat: true
        triggeredOnStart: true
        interval: 1500 + Math.random() * 1800
        onTriggered: {
            interval = 1500 + Math.random() * 1800;
            root._wanderX = (Math.random() * 2 - 1) * 0.6;
            root._wanderY = (Math.random() * 2 - 1) * 0.45;
        }
    }

    property real _blinkScale: 1.0
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "_blinkScale"; to: 0.08; duration: 60; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "_blinkScale"; to: 1.0; duration: 90; easing.type: Easing.OutQuad }
    }
    Timer {
        running: true
        repeat: true
        interval: 2600 + Math.random() * 3400
        onTriggered: { interval = 2600 + Math.random() * 3400; blinkAnim.restart(); }
    }

    implicitWidth: root.size
    implicitHeight: root.size

    // Groessenaenderung (Slider) weich animiert statt hart zu springen.
    Behavior on size {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
    }

    function squash(edge) {
        // Harter Sprung auf den Stauch-Wert, danach sofort zurueck auf 1 --
        // die Behavior-SpringAnimation unten uebernimmt den Rueckweg als
        // sichtbare Federung. Kein Konflikt mit einer deklarativen Bindung,
        // da squashX/squashY nirgends sonst gebunden sind (siehe
        // feedback_qml_animation_on_bound_property).
        const dev = 0.28 * root.jiggle;
        if (edge === "left" || edge === "right") {
            root._squashX = 1.0 - dev;
            root._squashY = 1.0 + dev;
        } else {
            root._squashX = 1.0 + dev;
            root._squashY = 1.0 - dev;
        }
        root._squashX = 1.0;
        root._squashY = 1.0;
    }

    property real _squashX: 1.0
    property real _squashY: 1.0
    Behavior on _squashX {
        SpringAnimation { spring: 3.2; damping: 0.28; mass: 0.5 }
    }
    Behavior on _squashY {
        SpringAnimation { spring: 3.2; damping: 0.28; mass: 0.5 }
    }

    // Sanftes Wachsen beim Greifen, zurueckfedern beim Loslassen.
    property real _grabScale: root.dragging ? 1.1 : 1.0
    Behavior on _grabScale {
        SpringAnimation { spring: 4.0; damping: 0.5 }
    }

    // Leichtes Atmen, nur wenn der Blob wirklich ruht (nicht waehrend Drag
    // oder waehrend er noch durch die Gegend fliegt).
    property real _idleScale: 1.0
    SequentialAnimation on _idleScale {
        id: idleAnim
        running: root.atRest && !root.dragging && root.jiggle > 0.01
        loops: Animation.Infinite
        NumberAnimation { to: 1.0 + 0.035 * root.jiggle; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
    }
    onAtRestChanged: if (!root.atRest || root.dragging) root._idleScale = 1.0
    onDraggingChanged: if (root.dragging) root._idleScale = 1.0

    // Formwechsel: kurzer "Pop" (kleiner Einzug + Feder zurueck) begleitet
    // den Crossfade zwischen den vier vorgefertigten Varianten. Eine echte
    // punktgenaue Pfad-Interpolation zwischen Rectangle/Shape-Varianten ist
    // ohne eigenen Geometrie-Interpolator nicht sinnvoll machbar -- diese
    // Kombination aus Crossfade + Pop ist die bewusst gewaehlte Annaeherung
    // an "Morphing" (siehe README).
    property real _shapePop: 1.0
    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: root; property: "_shapePop"; to: 0.82; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shapePop"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
    }
    onShapeKindChanged: popAnim.restart()

    // Reihenfolge: erst zur Zugachse drehen, dort laenglich strecken (Gummi-
    // band-Effekt), zurueckdrehen, dann die bestehende isotrope Skalierung
    // (Greifen/Atmen/Aufprall-Squash/Formwechsel-Pop) obendrauf -- bei
    // pullX=pullY=0 (kein Zug) sind Rotation/Streck-Scale Identitaet, siehe
    // _pullMag oben.
    transform: [
        Rotation { origin.x: root.width / 2; origin.y: root.height / 2; angle: root._pullAngle },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: 1 + 0.35 * root._pullMag
            yScale: 1 - 0.22 * root._pullMag
        },
        Rotation { origin.x: root.width / 2; origin.y: root.height / 2; angle: -root._pullAngle },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root._grabScale * root._idleScale * root._squashX * root._shapePop
            yScale: root._grabScale * root._idleScale * root._squashY * root._shapePop
        }
    ]

    function _squirclePath(sz, exp) {
        const a = sz / 2;
        const N = 48;
        let d = "";
        for (let i = 0; i <= N; i++) {
            const t = (i / N) * Math.PI * 2;
            const ct = Math.cos(t), st = Math.sin(t);
            const x = a + Math.sign(ct) * Math.pow(Math.abs(ct), 2 / exp) * a;
            const y = a + Math.sign(st) * Math.pow(Math.abs(st), 2 / exp) * a;
            d += (i === 0 ? "M " : "L ") + x.toFixed(2) + " " + y.toFixed(2) + " ";
        }
        return d + "Z";
    }

    // Deterministischer Jitter (kein Math.random -- soll bei jedem Neustart
    // gleich aussehen) + zeitbasiertes Wabern fuers "Atmen" der organischen
    // Form selbst (zusaetzlich zur generischen _idleScale-Atmung oben).
    readonly property var _organicJitter: [0.14, -0.08, 0.11, -0.13, 0.09, -0.10, 0.13, -0.07]
    property real _organicT: 0
    NumberAnimation on _organicT {
        from: 0; to: Math.PI * 2
        duration: 9000
        loops: Animation.Infinite
    }

    function _organicPath(sz) {
        const N = 8;
        const c = sz / 2;
        const baseR = c * 0.86;
        const pts = [];
        for (let i = 0; i < N; i++) {
            const a = (i / N) * Math.PI * 2;
            const wob = Math.sin(root._organicT + i * 1.7) * 0.045 * root.jiggle;
            const r = baseR * (1 + root._organicJitter[i] + wob);
            pts.push({ x: c + Math.cos(a) * r, y: c + Math.sin(a) * r });
        }
        const t = 1 / 6;
        function ctrl1(i) {
            const prev = pts[(i - 1 + N) % N], next = pts[(i + 1) % N], p = pts[i];
            return { x: p.x + (next.x - prev.x) * t, y: p.y + (next.y - prev.y) * t };
        }
        function ctrl2(i) {
            const prev = pts[(i - 1 + N) % N], next = pts[(i + 1) % N], p = pts[i];
            return { x: p.x - (next.x - prev.x) * t, y: p.y - (next.y - prev.y) * t };
        }
        let d = `M ${pts[0].x.toFixed(2)} ${pts[0].y.toFixed(2)} `;
        for (let i = 0; i < N; i++) {
            const next = (i + 1) % N;
            const c1 = ctrl1(i);
            const c2 = ctrl2(next);
            d += `C ${c1.x.toFixed(2)} ${c1.y.toFixed(2)} ${c2.x.toFixed(2)} ${c2.y.toFixed(2)} ${pts[next].x.toFixed(2)} ${pts[next].y.toFixed(2)} `;
        }
        return d + "Z";
    }

    Rectangle {
        id: circleVisual
        anchors.fill: parent
        radius: width / 2
        color: root.blobColor
        visible: opacity > 0
        opacity: root.shapeKind === "circle" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Rectangle {
        id: roundedSquareVisual
        anchors.fill: parent
        radius: width * 0.22
        color: root.blobColor
        visible: opacity > 0
        opacity: root.shapeKind === "roundedSquare" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Shape {
        id: squircleVisual
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.shapeKind === "squircle" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.blobColor
            strokeWidth: -1
            PathSvg { path: root._squirclePath(root.size, 4) }
        }
    }

    Shape {
        id: organicVisual
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.shapeKind === "organic" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.blobColor
            strokeWidth: -1
            PathSvg { path: root._organicPath(root.size) }
        }
    }

    // Augen obendrauf, unabhaengig von der Form -- feste, leicht ueber der
    // Mitte liegende Position wirkt bei allen vier Formen natuerlich genug.
    Item {
        id: eyes
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.size * 0.24
        width: eyeSize * 2 + eyeGap
        height: eyeSize
        visible: root.size > 34

        readonly property real eyeSize: root.size * 0.26
        readonly property real eyeGap: root.size * 0.18
        readonly property real pupilSize: eyeSize * 0.46
        readonly property real maxOffset: (eyeSize - pupilSize) / 2 * 0.85

        Repeater {
            model: 2
            delegate: Item {
                id: eyeItem
                required property int index
                width: eyes.eyeSize
                height: eyes.eyeSize
                x: index * (eyes.eyeSize + eyes.eyeGap)
                transform: Scale {
                    origin.x: eyeItem.width / 2
                    origin.y: eyeItem.height / 2
                    yScale: root._blinkScale
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "white"
                }
                Rectangle {
                    width: eyes.pupilSize
                    height: eyes.pupilSize
                    radius: width / 2
                    color: "#26262b"
                    x: (parent.width - width) / 2 + root._lookX * eyes.maxOffset
                    y: (parent.height - height) / 2 + root._lookY * eyes.maxOffset
                }
            }
        }
    }
}
