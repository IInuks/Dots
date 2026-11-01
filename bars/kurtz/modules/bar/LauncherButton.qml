import QtQuick
import "../../"
import "../../components"

// The "home planet": a ringed accent orb that opens the launcher.
// On hover a tiny moon starts orbiting it.
// Companion black hole (Config launcherHole):
//   orbit  = circles the planet on a tilted ellipse, passing behind it on
//            the upper half and in front of it on the lower half
//   beside = parked to the right of the planet, only its disk spins
//   off    = none
Item {
    id: root
    signal clicked

    readonly property string holeMode: Theme.c.launcherHole
    readonly property bool hasHole: holeMode === "orbit" || holeMode === "beside"

    implicitWidth: Theme.pillHeight * (holeMode === "orbit" ? 1.75 : holeMode === "beside" ? 1.55 : 1) + 6
    implicitHeight: Theme.pillHeight
    Behavior on implicitWidth { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut } }

    // Orbit angle in degrees (0 = right, 90 = front/bottom).
    property real orbitAngle: 25
    NumberAnimation on orbitAngle {
        running: root.holeMode === "orbit" && Theme.c.blackHoleSpin && Theme.animations
        from: 25
        to: 385
        duration: Math.round(14000 / Math.max(0.1, Theme.c.blackHoleSpeed))
        loops: Animation.Infinite
    }
    readonly property real _a: orbitAngle * Math.PI / 180
    readonly property bool _front: Math.sin(_a) > 0

    readonly property bool _homeHole: Theme.c.planetStyle === "blackhole"

    Orb {
        id: planet
        z: 1
        opacity: root._homeHole ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        anchors.verticalCenter: parent.verticalCenter
        x: (root.holeMode === "beside" ? Theme.pillHeight * 0.52 : root.width / 2) - width / 2
        Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut } }
        width: Theme.pillHeight * 0.66
        height: width
        color: Theme.accent
        ring: Theme.c.planetRings
        glowing: mouse.containsMouse
        scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1.1 : 1
        squash: mouse.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easePop; easing.overshoot: 2 } }
        Behavior on squash { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop; easing.overshoot: 2.5 } }
    }

    // home planet as a black hole (Config planetStyle), same place + motion
    BlackHole {
        z: 1
        anchors.centerIn: planet
        width: Theme.pillHeight * 0.95
        height: width
        palette: "tint"
        tint: Theme.accent
        glowStrength: mouse.containsMouse ? 1.0 : 0.6
        visible: opacity > 0.01
        opacity: root._homeHole ? 1 : 0
        scale: planet.scale
    }

    // companion black hole
    BlackHole {
        id: hole
        readonly property real depth: root.holeMode === "orbit" ? 1 + Math.sin(root._a) * 0.18 : 1
        width: Theme.pillHeight * 0.5 * depth * (mouse.containsMouse ? 1.12 : 1)
        height: width
        z: root.holeMode === "orbit" && !root._front ? 0 : 2
        x: (root.holeMode === "orbit" ? planet.x + planet.width / 2 + Math.cos(root._a) * Theme.pillHeight * 0.66 : root.width - Theme.pillHeight * 0.55) - width / 2
        y: (root.holeMode === "orbit" ? root.height / 2 + Math.sin(root._a) * Theme.pillHeight * 0.14 - Math.cos(root._a) * Theme.pillHeight * 0.1 : root.height / 2) - height / 2
        glowStrength: 0.45
        visible: opacity > 0.01
        opacity: root.hasHole ? 1 : 0
        scale: root.hasHole ? 1 : 0.2
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.6 } }
    }

    // orbiting moon
    Item {
        id: orbit
        z: 3
        anchors.centerIn: planet
        width: Theme.pillHeight * 1.05
        height: width
        opacity: mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        Orb {
            width: 6
            height: 6
            x: parent.width - width
            y: parent.height / 2 - 3
            color: Theme.yellow
            rim: false
        }
        RotationAnimation on rotation {
            running: mouse.containsMouse && Theme.animations
            from: 0
            to: 360
            duration: 2600
            loops: Animation.Infinite
        }
    }

    MouseArea {
        id: mouse
        z: 4
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
