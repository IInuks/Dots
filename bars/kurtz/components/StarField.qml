import QtQuick
import "../"

// Far depth layer: tiny twinkling stars, a few nebula glows and the odd
// shooting star.
//
// Positions are *deterministic* (hash of index + seed), so the sky looks
// the same after every reload. Each star twinkles on its own 3-8 s cycle.
// All animations stop when the field is invisible or `active` is false.
Item {
    id: root

    property int count: Theme.c.starCount
    property int seed: 1
    property bool active: true
    property real inset: 0           // keep stars away from rounded corners
    property bool nebula: true       // big soft glows behind content
    property bool shooting: Theme.c.shootingStars
    property bool sparkles: true     // the two "+" stars
    property bool twinkle: true      // per-field switch (the bar turns it off by default)
    property real maxSize: 2.6
    property var tints: [Theme.text, Theme.text, Theme.text, Theme.accent, Theme.yellow, Theme.magenta]

    readonly property bool _run: active && visible && Theme.stars
    readonly property bool _twinkle: _run && Theme.twinkle && twinkle

    visible: Theme.stars

    // Cheap stable pseudo-random in [0,1).
    function rnd(i, salt) {
        const x = Math.sin(i * 12.9898 + root.seed * 78.233 + salt * 37.719) * 43758.5453;
        return x - Math.floor(x);
    }

    // ---- nebula glows (3 big soft blobs)
    Repeater {
        model: root.nebula && Theme.c.nebula ? 3 : 0
        Glow {
            required property int index
            readonly property real sz: Math.min(root.width, root.height) * (0.9 + root.rnd(index, 9) * 0.9)
            width: sz
            height: sz
            x: root.rnd(index, 7) * root.width - sz / 2
            y: root.rnd(index, 8) * root.height - sz / 2
            color: [Theme.accent, Theme.purple, Theme.magenta][index % 3]
            strength: 0.28
        }
    }

    // ---- stars
    Repeater {
        model: root.count
        Rectangle {
            id: star
            required property int index
            readonly property real r0: root.rnd(index, 1)
            readonly property real r1: root.rnd(index, 2)
            readonly property real r2: root.rnd(index, 3)
            readonly property real baseOpacity: 0.2 + r2 * 0.6

            // Most stars are tiny, a few are bigger.
            width: 1 + Math.pow(root.rnd(index, 4), 3) * (root.maxSize - 1)
            height: width
            radius: width / 2
            x: root.inset + r0 * Math.max(0, root.width - 2 * root.inset)
            y: root.inset + r1 * Math.max(0, root.height - 2 * root.inset)
            color: root.tints[Math.floor(root.rnd(index, 5) * root.tints.length)]
            opacity: baseOpacity

            SequentialAnimation on opacity {
                running: root._twinkle
                loops: Animation.Infinite
                PauseAnimation { duration: 400 + star.r0 * 4000 }
                NumberAnimation { to: star.baseOpacity * 0.25; duration: 1500 + star.r1 * 2500; easing.type: Easing.InOutSine }
                NumberAnimation { to: star.baseOpacity; duration: 1500 + star.r2 * 2500; easing.type: Easing.InOutSine }
            }
        }
    }

    // ---- two four-point "sparkle" stars (the Kurzgesagt plus shape)
    Repeater {
        model: root.sparkles && root.count > 10 ? 2 : 0
        Item {
            id: sparkle
            required property int index
            readonly property real sz: 7 + root.rnd(index, 11) * 4
            width: sz
            height: sz
            x: root.inset + root.rnd(index, 12) * Math.max(0, root.width - 2 * root.inset - sz)
            y: root.inset + root.rnd(index, 13) * Math.max(0, root.height - 2 * root.inset - sz)
            opacity: 0.7
            Rectangle { anchors.centerIn: parent; width: parent.width; height: 1.6; radius: 1; color: Theme.text }
            Rectangle { anchors.centerIn: parent; width: 1.6; height: parent.height; radius: 1; color: Theme.text }
            SequentialAnimation on scale {
                running: root._twinkle
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 2600 + sparkle.index * 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 2600 + sparkle.index * 900; easing.type: Easing.InOutSine }
            }
        }
    }

    // ---- shooting star: every ~cometEvery s (0.6x-1.4x) a streak crosses the field
    Item {
        id: comet
        visible: false
        width: 70
        height: 2
        rotation: 18
        transformOrigin: Item.Right

        Rectangle {
            anchors.fill: parent
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(Theme.text, 0) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.text, 0.9) }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 3
            radius: 1.5
            color: Theme.text
        }

        ParallelAnimation {
            id: cometAnim
            onFinished: comet.visible = false
            NumberAnimation { target: comet; property: "x"; from: comet._x0; to: comet._x0 + root.width * 0.35; duration: 900; easing.type: Easing.InQuad }
            NumberAnimation { target: comet; property: "y"; from: comet._y0; to: comet._y0 + root.width * 0.35 * 0.32; duration: 900; easing.type: Easing.InQuad }
            SequentialAnimation {
                NumberAnimation { target: comet; property: "opacity"; from: 0; to: 1; duration: 200 }
                PauseAnimation { duration: 400 }
                NumberAnimation { target: comet; property: "opacity"; to: 0; duration: 300 }
            }
        }
        property real _x0: 0
        property real _y0: 0
        property int _n: 0
    }

    Timer {
        running: root._twinkle && root.shooting && root.width > 200
        repeat: true
        interval: Theme.c.cometEvery * 1000 * (0.6 + root.rnd(comet._n, 21) * 0.8)
        onTriggered: {
            comet._n += 1;
            comet._x0 = root.rnd(comet._n, 22) * root.width * 0.6;
            comet._y0 = -10 + root.rnd(comet._n, 23) * root.height * 0.3;
            comet.visible = true;
            cometAnim.restart();
        }
    }
}
