import QtQuick

// Konfetti-Ebene ueber der ganzen Leiste. Jedes Schnipsel fliegt auf einer
// Wurfparabel und raeumt sich danach selbst weg -- ohne laufende Timer,
// solange nichts ausgepackt wird.
Item {
    id: root

    function burst(x, y, colors) {
        for (let i = 0; i < Config.confettiPieces; i++) {
            const a = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 1.1;
            const speed = 110 + Math.random() * 170;
            piece.createObject(root, {
                x0: x + (Math.random() - 0.5) * 16,
                y0: y,
                vx: Math.cos(a) * speed,
                vy: Math.sin(a) * speed,
                spin: (Math.random() - 0.5) * 1100,
                color: colors[i % colors.length],
                width: 3 + Math.random() * 4,
                height: 6 + Math.random() * 5,
                radius: Math.random() < 0.3 ? 4 : 1
            });
        }
    }

    Component {
        id: piece
        Rectangle {
            id: bit
            property real x0
            property real y0
            property real vx
            property real vy
            property real spin
            property real t: 0
            readonly property real secs: t * 1.3
            x: x0 + vx * secs
            y: y0 + vy * secs + 230 * secs * secs
            rotation: spin * secs
            opacity: t < 0.65 ? 1 : (1 - t) / 0.35
            NumberAnimation {
                id: fly
                target: bit
                property: "t"
                from: 0
                to: 1
                duration: 1300
                onFinished: bit.destroy()
            }
            Component.onCompleted: fly.start()
        }
    }
}
