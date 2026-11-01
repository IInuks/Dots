import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

// One reusable "liquid" trigger+menu pair.
//
// This Item sits inline in the bar's row layout and only hosts the trigger
// visual. The actual dropdown (a single flat Shape fused to the bar's
// edge, plus its content) is reparented onto `menuLayer`, a full-window
// overlay Item supplied by Bar.qml, and positioned by mapping the
// trigger's coordinates into that overlay. This is what lets the menu
// float freely past the bar without being clipped by the row layout that
// contains its trigger.
//
// The bar can dock to any of the 4 screen edges (Settings.barPosition), so
// the menu has to be able to flow out of any of them too: down from a top
// bar, up from a bottom bar, right from a left bar, left from a right bar.
// Rather than 4 near-duplicate shapes, the fillet path below is built in a
// local (u, v) frame -- u runs along the bar edge, v runs away from it,
// exactly like the original top-bar-only version -- and then mapped into
// screen x/y per edge in edgePoint(). Only that mapping (plus the
// trigger-anchor corner picked in chainOffset()) is edge-specific.
Item {
    id: root

    // -- required wiring, set by the instantiating module --
    required property Item menuLayer
    required property Component trigger
    required property Component content

    // -- geometry --
    property real menuWidth: 222
    property real menuContentHeight: 200
    // Vertical bars run these menus off a thinner, taller strip, so
    // everything gets a bit more breathing room than the horizontal case.
    readonly property real effMenuWidth: menuWidth * (Settings.vertical ? 1.2 : 1)
    readonly property real effMenuContentHeight: menuContentHeight * (Settings.vertical ? 1.2 : 1)
    property real topRadius: Theme.menuTopRadius
    property real bottomRadius: Theme.menuBottomRadius
    property real edgeMargin: 8
    // When set, ignore the trigger's own cross-axis position and align the
    // popup's cross-axis center with this other item instead (e.g. the
    // launcher: its trigger, the clock, sits at the very top of a vertical
    // bar, but the popup itself should open level with the workspace dots).
    property Item alignTarget: null
    // Set false to stop hovering the trigger itself from opening the menu
    // (paired with externalHover below, for moving the open-gesture onto a
    // different item entirely -- e.g. the launcher opens off the workspace
    // dots instead of the clock in vertical mode).
    property bool triggerHoverEnabled: true
    // Sticks the open/close behavior to some other item's hover, exactly as
    // if that item's hover was the trigger's own (participates in the same
    // close-on-unhover timer as triggerHover/contentHover).
    property bool externalHover: false

    // -- state --
    property bool open: false
    // Keeps the menu open regardless of hover, for external (e.g. IPC/
    // keybind-driven) toggling instead of mouse-only hover.
    property bool pinned: false
    property real openHeight: 0
    // Live geometry of the floating shape, for the window's input mask
    // (Bar.qml unions this with the bar strip; collapses to nothing when closed).
    readonly property alias hitArea: floater
    Behavior on openHeight {
        NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
    }

    // Whichever axis runs along the bar (length) is left to fill the
    // GridLayout cell; the cross axis (bar thickness) takes the trigger's
    // own reported size, which each trigger already keys off
    // Settings.barThickness when Settings.vertical is true.
    Layout.preferredWidth: triggerLoader.implicitWidth
    Layout.preferredHeight: triggerLoader.implicitHeight
    Layout.fillWidth: Settings.vertical
    Layout.fillHeight: !Settings.vertical
    implicitWidth: triggerLoader.implicitWidth
    implicitHeight: triggerLoader.implicitHeight

    Loader {
        id: triggerLoader
        sourceComponent: root.trigger
        anchors.centerIn: parent
    }

    HoverHandler {
        id: triggerHover
        enabled: root.triggerHoverEnabled
        onHoveredChanged: root.updateOpen()
    }

    onExternalHoverChanged: updateOpen()

    function updateOpen() {
        // Hover (and pinned/externalHover) only ever opens now -- moving the
        // mouse away no longer auto-closes. Closing is explicit: Esc,
        // click-outside (see Bar.qml's dismissCatcher -> close()), or pinned
        // turning false while nothing is still hovering (below).
        if (root.pinned || triggerHover.hovered || floater.contentHover.hovered || root.externalHover) {
            open = true;
        }
    }

    onPinnedChanged: {
        if (root.pinned) {
            open = true;
        } else if (!triggerHover.hovered && !floater.contentHover.hovered && !root.externalHover) {
            open = false;
        }
    }

    // Explicit close request from outside (Esc / click-outside). Ignored
    // while pinned -- something specifically needs this open right now
    // (e.g. SettingsMenu's Commands tab keeps a shortcut's result badge
    // visible via pinned while it's still running).
    function close() {
        if (root.pinned) return;
        root.open = false;
    }
    onOpenChanged: openHeight = open ? effMenuContentHeight : 0

    // The floating shape + content, reparented onto the shared overlay.
    Item {
        id: floater
        parent: root.menuLayer
        z: 1000

        property alias contentHover: contentHoverHandler
        readonly property real crossSize: root.effMenuWidth + root.topRadius * 2 // extent along the bar edge
        readonly property real growSize: Math.max(root.openHeight, 0)         // extent away from the bar
        readonly property real h: growSize // kept for the elements below that only ever meant "current animated extent"

        readonly property string edge: Settings.barPosition // "top" | "bottom" | "left" | "right"
        readonly property bool vertical: edge === "left" || edge === "right"

        // Once h drops below the combined fillet+corner height, the two
        // fixed-size curves would overlap and self-intersect (visible as a
        // stray corner during the close animation). Scale both radii down
        // together so they always exactly fit within the current height —
        // real geometry, not a squash-transform, so they stay circular.
        readonly property real totalRadius: root.topRadius + root.bottomRadius
        readonly property real radiusScale: totalRadius > 0 ? Math.min(1, h / totalRadius) : 0
        readonly property real effTopRadius: root.topRadius * radiusScale
        readonly property real effBottomRadius: root.bottomRadius * radiusScale

        // Sum root's offset up through its ancestor layouts to the shared
        // parent of `menuLayer`, reading each `.x`/`.y` as a plain property
        // access so every intermediate layout pass is a tracked dependency.
        // (A single Item.mapToItem(menuLayer, ...) call does *not* reliably
        // re-run here: layout-computed positions like a horizontally-
        // centered `x` can settle to their final value without
        // retriggering it, leaving the anchor stale.)
        //
        // Which corner of the trigger we anchor from depends on which edge
        // the bar is docked to: the anchor always sits on the trigger's
        // side that touches the bar's outer edge (bottom of the trigger
        // for a top bar, right of the trigger for a left bar, etc).
        function chainOffset() {
            if (!root.menuLayer) return Qt.point(0, 0);
            const commonParent = root.menuLayer.parent;
            let gx, gy;
            switch (floater.edge) {
                case "bottom": gx = root.width / 2; gy = 0; break;
                case "left":   gx = root.width;      gy = root.height / 2; break;
                case "right":  gx = 0;               gy = root.height / 2; break;
                default:       gx = root.width / 2; gy = root.height; break; // top
            }
            let item = root;
            while (item && item.parent && item.parent !== commonParent) {
                gx += item.x;
                gy += item.y;
                item = item.parent;
            }
            if (item) { gx += item.x; gy += item.y; }
            return Qt.point(gx, gy);
        }

        readonly property point anchor: chainOffset()

        // Same ancestor-walk as chainOffset(), but to the center of an
        // arbitrary other item instead of a corner of the trigger.
        function targetOffset() {
            if (!root.alignTarget || !root.menuLayer) return null;
            const commonParent = root.menuLayer.parent;
            let gx = root.alignTarget.width / 2;
            let gy = root.alignTarget.height / 2;
            let item = root.alignTarget;
            while (item && item.parent && item.parent !== commonParent) {
                gx += item.x;
                gy += item.y;
                item = item.parent;
            }
            if (item) { gx += item.x; gy += item.y; }
            return Qt.point(gx, gy);
        }

        readonly property var alignPoint: targetOffset()

        x: {
            if (!root.menuLayer) return 0;
            if (edge === "left") return anchor.x;
            if (edge === "right") return anchor.x - growSize;
            const centerX = alignPoint ? alignPoint.x : anchor.x;
            return Math.max(root.edgeMargin, Math.min(centerX - crossSize / 2, root.menuLayer.width - crossSize - root.edgeMargin));
        }
        y: {
            if (!root.menuLayer) return 0;
            if (edge === "top") return anchor.y;
            if (edge === "bottom") return anchor.y - growSize;
            const centerY = alignPoint ? alignPoint.y : anchor.y;
            return Math.max(root.edgeMargin, Math.min(centerY - crossSize / 2, root.menuLayer.height - crossSize - root.edgeMargin));
        }
        width: vertical ? growSize : crossSize
        height: vertical ? crossSize : growSize

        visible: h > 0.5

        HoverHandler {
            id: contentHoverHandler
            onHoveredChanged: root.updateOpen()
        }

        // Builds the fillet outline in a local (u, v) frame -- u along the
        // bar edge (0..crossSize), v away from it (0..growSize) -- then
        // maps each point through edgePoint() for the current edge. The
        // frame itself is exactly the original top-bar path.
        function edgePoint(u, v) {
            switch (edge) {
                case "bottom": return [u, growSize - v];
                case "left":   return [v, u];
                case "right":  return [growSize - v, u];
                default:       return [u, v]; // top
            }
        }

        readonly property string svgPath: {
            const rt = effTopRadius, rb = effBottomRadius, cs = crossSize, gs = growSize;
            const pts = [
                ["M", [0, 0]],
                ["Q", [rt, 0], [rt, rt]],
                ["L", [rt, gs - rb]],
                ["Q", [rt, gs], [rt + rb, gs]],
                ["L", [cs - rt - rb, gs]],
                ["Q", [cs - rt, gs], [cs - rt, gs - rb]],
                ["L", [cs - rt, rt]],
                ["Q", [cs - rt, 0], [cs, 0]],
                ["L", [0, 0]],
                ["Z", []]
            ];
            return pts.map(([cmd, ...coords]) => {
                if (cmd === "Z") return "Z";
                const mapped = coords.map(([u, v]) => edgePoint(u, v).join(","));
                return cmd + " " + mapped.join(" ");
            }).join(" ");
        }

        Shape {
            id: shape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.surface
                strokeWidth: -1
                PathSvg { path: floater.svgPath }
            }
        }

        Item {
            id: contentArea
            // A few px of inset on every side so text never sits flush
            // against (or past) the shape's straight edges. On the grow
            // axis the near inset (next to whichever edge touches the bar)
            // can be tighter -- that corner is a fillet transition, not
            // really "content" space -- but the far inset (away from the
            // bar, where e.g. SysMon's numbers land) needs the same
            // breathing room the cross axis already gets.
            readonly property real growNearInset: root.topRadius * 0.5
            readonly property real growFarInset: root.topRadius + 6
            readonly property real growContentSize: Math.max(floater.h - growNearInset - growFarInset, 0)
            readonly property real growPos: (floater.edge === "top" || floater.edge === "left") ? growNearInset : growFarInset

            x: floater.vertical ? growPos : (root.topRadius + 6)
            y: floater.vertical ? (root.topRadius + 6) : growPos
            width: floater.vertical ? growContentSize : (root.effMenuWidth - 12)
            height: floater.vertical ? (root.effMenuWidth - 12) : growContentSize
            clip: true
            opacity: root.open ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: root.open ? 150 : 0 }
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }

            Loader {
                anchors.fill: parent
                active: floater.visible
                sourceComponent: root.content
            }
        }
    }
}
