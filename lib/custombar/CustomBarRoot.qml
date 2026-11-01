import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."

// The actual running custom bar. Reads its own config
// (~/.local/state/quickdots/custom-bars/<slug>.json), written by the
// "Eigene" editor tab in the menu, and renders it -- either as one
// continuous strip ("bar") or three separate floating islands ("islands").
Item {
    id: root

    required property string slug

    property FileView _config: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickdots/custom-bars/" + root.slug + ".json"
        printErrors: false
        watchChanges: true
        adapter: JsonAdapter {
            property string name: ""
            property string style: "bar"
            property string position: "top"
            property var zones: ({ left: [], center: [], right: [] })
            property var theme: ({ mode: "dark", surface: "#1c1c26", foreground: "#e8e8f0", accent: "#5b8cff", opacity: 0.9, radius: 14 })
            property var islands: ({
                left: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
                center: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 }),
                right: ({ shape: "rounded", height: 34, padding: 10, width: 0, angle: 0, dx: 0 })
            })
        }
        onFileChanged: reload()
    }

    // Not a singleton -- see ModuleRegistry.qml's top comment.
    WalTheme { id: wal }

    readonly property var cfg: _config.adapter
    readonly property bool adaptive: cfg.theme.mode === "adaptive"
    readonly property color surfaceColor: root.adaptive ? wal.surface : (cfg.theme.surface || "#1c1c26")
    readonly property color fgColor: root.adaptive ? wal.foreground : (cfg.theme.foreground || "#e8e8f0")
    readonly property color accentColor: root.adaptive ? wal.accent : (cfg.theme.accent || "#5b8cff")
    readonly property real opacityVal: cfg.theme.opacity !== undefined ? cfg.theme.opacity : 0.9
    readonly property real radiusVal: cfg.theme.radius !== undefined ? cfg.theme.radius : 14
    readonly property int barHeight: 34

    function islandCfg(zone) {
        return (root.cfg.islands && root.cfg.islands[zone]) || { shape: "rounded", height: root.barHeight, padding: 10, width: 0, angle: 0, dx: 0 };
    }

    Variants {
        model: Quickshell.screens

        delegate: Item {
            id: screenRoot
            required property var modelData
            readonly property var screen: modelData

            Loader {
                active: root.cfg.style !== "islands"
                sourceComponent: barStrip
            }
            Loader {
                active: root.cfg.style === "islands"
                sourceComponent: islandsGroup
            }

            // -- Style "bar": one continuous full-width strip. -------------
            Component {
                id: barStrip

                PanelWindow {
                    id: bar
                    screen: screenRoot.screen

                    anchors.top: root.cfg.position !== "bottom"
                    anchors.bottom: root.cfg.position === "bottom"
                    anchors.left: true
                    anchors.right: true
                    implicitHeight: root.barHeight
                    // 0, not root.barHeight -- windows tile/maximize into the
                    // full screen and the bar overlaps them (still drawn on
                    // top, WlrLayer.Top already stacks above normal windows
                    // regardless of exclusiveZone; this only ever affected
                    // the reserved gap, not paint order).
                    exclusiveZone: 0
                    color: "transparent"

                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "custombar-" + root.slug
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, root.opacityVal)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 14

                        ZoneContent {
                            items: root.cfg.zones.left || []
                            foreground: root.fgColor
                            accent: root.accentColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: centerZone.implicitHeight

                            ZoneContent {
                                id: centerZone
                                anchors.centerIn: parent
                                items: root.cfg.zones.center || []
                                foreground: root.fgColor
                                accent: root.accentColor
                            }
                        }

                        ZoneContent {
                            items: root.cfg.zones.right || []
                            foreground: root.fgColor
                            accent: root.accentColor
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }

            // -- Style "islands": three separate floating surfaces. -------
            // WlrLayer.Overlay same as bars/floating/IslandBase.qml (avoids
            // the click-away catcher swallowing clicks meant for island
            // content). Unlike IslandBase, every island here anchors ONLY
            // the left edge (never right, never leaving both unanchored for
            // "center") and gets its horizontal position from an explicit
            // margins.left computed against the screen's own width -- that's
            // what lets a per-island dx offset (from the editor's drag
            // preview, see menu/custom/BarPreview.qml) apply uniformly to
            // all three, including "center", which would otherwise rely on
            // the compositor's own unanchored-surface centering and have no
            // anchored edge for a margin to push against.
            //
            // All three sit on the same margins.top/bottom -- no per-island
            // vertical offset -- so islands always line up on one height,
            // only their horizontal position (dx) is independently
            // adjustable. "angle" rotates the visible chip only; the
            // PanelWindow itself stays axis-aligned and is sized to the
            // *bounding box* of the rotated rect (standard rotated-rect
            // bbox: |w·cosθ| + |h·sinθ| etc.) so a tilted island's corners
            // never get clipped by its own window.
            Component {
                id: islandsGroup

                Item {
                    Repeater {
                        model: ["left", "center", "right"]
                        delegate: PanelWindow {
                            id: island
                            required property string modelData
                            screen: screenRoot.screen

                            readonly property var _islandCfg: root.islandCfg(island.modelData)
                            readonly property string _shape: island._islandCfg.shape || "rounded"
                            readonly property real _height: island._islandCfg.height || root.barHeight
                            readonly property real _padding: island._islandCfg.padding !== undefined ? island._islandCfg.padding : 10
                            readonly property real _width: island._islandCfg.width || 0
                            readonly property real _angle: island._islandCfg.angle || 0
                            readonly property real _dx: island._islandCfg.dx || 0
                            readonly property real _screenW: screenRoot.screen ? screenRoot.screen.width : 0

                            // Logical (unrotated) chip size: content-fit,
                            // unless "width" asks for something wider.
                            readonly property real _rectW: Math.max(zone.implicitWidth + island._padding * 2, island._width)
                            readonly property real _rectH: island._height

                            readonly property real _rad: island._angle * Math.PI / 180
                            readonly property real _bboxW: Math.abs(island._rectW * Math.cos(island._rad)) + Math.abs(island._rectH * Math.sin(island._rad))
                            readonly property real _bboxH: Math.abs(island._rectW * Math.sin(island._rad)) + Math.abs(island._rectH * Math.cos(island._rad))

                            anchors.top: root.cfg.position !== "bottom"
                            anchors.bottom: root.cfg.position === "bottom"
                            anchors.left: true
                            margins.top: 6
                            margins.bottom: 6
                            margins.left: {
                                if (island.modelData === "left") return 8 + island._dx;
                                if (island.modelData === "right") return island._screenW - island.implicitWidth - 8 + island._dx;
                                return (island._screenW - island.implicitWidth) / 2 + island._dx;
                            }

                            implicitWidth: Math.max(1, island._bboxW)
                            implicitHeight: Math.max(1, island._bboxH)
                            exclusiveZone: 0
                            color: "transparent"

                            WlrLayershell.layer: WlrLayer.Overlay
                            WlrLayershell.namespace: "custombar-" + root.slug + "-" + island.modelData
                            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                            Rectangle {
                                anchors.centerIn: parent
                                width: island._rectW
                                height: island._rectH
                                rotation: island._angle
                                radius: island._shape === "pill" ? island._rectH / 2 : island._shape === "square" ? 4 : Math.min(root.radiusVal, 14)
                                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, root.opacityVal)

                                ZoneContent {
                                    id: zone
                                    anchors.centerIn: parent
                                    items: root.cfg.zones[island.modelData] || []
                                    foreground: root.fgColor
                                    accent: root.accentColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
