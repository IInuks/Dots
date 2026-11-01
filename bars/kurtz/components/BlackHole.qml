import QtQuick
import QtQuick.Shapes
import "../"

// A tiny Kurzgesagt black hole, built from flat layers like Orb.qml.
//
//        .-~~~~~-.             layer 0  glow      soft disk-colored halo
//      (  .---.  )             layer 1  lensing   thin ring around the core:
//   ===( (  ●  ) )===                              the disk's far side, bent
//      (  '---'  )                                 over the top by gravity
//        '-~~~~~-'             layer 2  disk back  tilted accretion disk,
//                                                  only the half behind the core
//                              layer 3  core      deep night-blue disc + photon ring
//                              layer 4  disk front the half passing in front
//                              layer 5  infall    specks spiralling in (big sizes)
//
// The disk is made of a few static colored arcs; "spinning" only rotates
// the item that holds them, so animation never re-tessellates a Shape.
// Both disk halves share one `spin` angle.
Item {
    id: root

    property string palette: Theme.c.blackHoleColor // warm | accent | violet | ice | tint
    property color tint: Theme.accent       // disk color for palette "tint"
    property bool spinning: Theme.c.blackHoleSpin
    property real speed: Theme.c.blackHoleSpeed
    property real tilt: -18                 // disk tilt in degrees, matches the planet rings
    property real flatten: 0.3              // disk height / width
    property real glowStrength: 0.55
    property bool infall: diameter >= 36    // spiralling specks (preview sizes only)

    readonly property real diameter: Math.min(width, height)
    readonly property real coreR: diameter * 0.19
    readonly property real diskR: diameter * 0.46
    readonly property real diskW: Math.max(1.2, diameter * 0.085)
    readonly property bool _run: spinning && Theme.animations && visible && opacity > 0

    // hot (inner, Doppler-bright side) -> mid -> cool (outer, dim side)
    readonly property var _palettes: ({
            warm: ["#FFF3C4", "#FB923C", "#F43F5E"],
            violet: ["#F5D0FE", "#E879F9", "#7C3AED"],
            ice: ["#E0F7FF", "#38BDF8", "#3B82F6"],
            accent: [Theme.highlightOf(Theme.accent), Theme.accent, Theme.accent2],
            tint: [Theme.highlightOf(tint), tint, Theme.mix(tint, "#7C3AED", 0.45)]
        })
    readonly property var _pal: _palettes[palette] || _palettes.warm
    readonly property color hot: _pal[0]
    readonly property color mid: _pal[1]
    readonly property color cool: _pal[2]

    property real spin: 0
    NumberAnimation on spin {
        running: root._run
        from: 0
        to: 360
        duration: Math.round(6500 / Math.max(0.1, root.speed))
        loops: Animation.Infinite
    }

    implicitWidth: 24
    implicitHeight: 24

    // ---- layer 0: glow
    Glow {
        anchors.centerIn: parent
        width: root.diameter * 1.5
        height: width
        color: root.mid
        strength: root.glowStrength
    }

    // ---- layer 1: lensed far side of the disk (Einstein ring look)
    Shape {
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        rotation: root.tilt
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.alpha(root.mid, 0.65)
            strokeWidth: Math.max(1, root.diskW * 0.45)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.diameter / 2
                centerY: root.diameter / 2
                radiusX: root.coreR * 1.4
                radiusY: root.coreR * 1.3
                startAngle: 180
                sweepAngle: 180
            }
        }
    }

    // ---- layer 2: back half of the accretion disk
    Item {
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        rotation: root.tilt
        Loader {
            anchors.fill: parent
            sourceComponent: diskComp
        }
    }

    // ---- layer 3: event horizon + photon ring
    Rectangle {
        anchors.centerIn: parent
        width: root.coreR * 2
        height: width
        radius: width / 2
        color: "#03041A"
        border.width: Math.max(1, root.diameter * 0.03)
        border.color: root.hot
        antialiasing: true
    }

    // ---- layer 4: front half, clipped to the lower half of the tilted
    // disk so it passes in front of the core.
    Item {
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        rotation: root.tilt
        Item {
            y: root.diameter / 2
            width: root.diameter
            height: root.diameter / 2
            clip: true
            Loader {
                y: -root.diameter / 2
                width: root.diameter
                height: root.diameter
                sourceComponent: diskComp
            }
        }

        // ---- layer 5: specks falling in on a flattening spiral
        Repeater {
            model: root.infall ? 3 : 0
            Rectangle {
                id: speck
                required property int index
                property real t: 0
                readonly property real a: (index * 120 + t * 540) * Math.PI / 180
                readonly property real r: root.diskR * 1.15 * (1 - t) + root.coreR * t
                width: Math.max(1.5, root.diameter * 0.035)
                height: width
                radius: width / 2
                color: root.hot
                x: root.diameter / 2 + Math.cos(a) * r - width / 2
                y: root.diameter / 2 + Math.sin(a) * r * root.flatten - height / 2
                // behind the core while on the far (upper) side
                opacity: (Math.sin(a) < 0 && r < root.coreR * 1.3 ? 0 : 1) * Math.min(1, t * 6) * (1 - t * 0.6)
                visible: root._run
                NumberAnimation on t {
                    running: root._run && root.infall
                    from: 0
                    to: 1
                    duration: Math.round((2600 + speck.index * 700) / Math.max(0.1, root.speed))
                    loops: Animation.Infinite
                }
            }
        }
    }

    // One flattened, spinning copy of the disk. Rotation happens *inside*
    // the flattening scale, so the colored clumps orbit along the ellipse.
    Component {
        id: diskComp
        Item {
            id: disk
            transform: Scale {
                origin.x: root.diameter / 2
                origin.y: root.diameter / 2
                yScale: root.flatten
            }
            Shape {
                anchors.fill: parent
                rotation: root.spin
                preferredRendererType: Shape.CurveRenderer

                component Arc: ShapePath {
                    property real r: root.diskR
                    property real from: 0
                    property real sweep: 90
                    strokeWidth: root.diskW
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: root.diameter / 2
                        centerY: root.diameter / 2
                        radiusX: r
                        radiusY: r
                        startAngle: from
                        sweepAngle: sweep
                    }
                }

                // outer band: hot clump, warm body, cool tail
                Arc { strokeColor: root.cool; from: 200; sweep: 130 }
                Arc { strokeColor: root.mid; from: 70; sweep: 125 }
                Arc { strokeColor: root.hot; from: 0; sweep: 60 }
                // inner band, thinner and offset so the clumps don't line up
                Arc { strokeColor: Theme.alpha(root.hot, 0.9); r: root.diskR * 0.68; strokeWidth: root.diskW * 0.6; from: 150; sweep: 100 }
                Arc { strokeColor: Theme.alpha(root.mid, 0.8); r: root.diskR * 0.68; strokeWidth: root.diskW * 0.6; from: 300; sweep: 70 }
            }
        }
    }
}
