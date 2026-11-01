import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../"

// Menus-prompt section 3, "Modus 'slice'": one card in the window
// switcher. Shares its base parallelogram geometry, width-expand
// animation and containmentMask limitation with
// Bar/launcher/SliceDelegate.qml (spec: "verwendet dieselben Maße wie
// der Launcher ... mit diesen Unterschieden") -- only the parts spec
// section 3 explicitly overrides (background, icon, shadow, border,
// badges, nameplate, edge-fade) differ below. roundCorners is left out
// for the same "ship the default" reason as the launcher (see README
// "Noch nicht gebaut").
Item {
    id: root

    required property var modelData // {id, title, appid, tags, is_focused, is_floating, ...}
    required property int index
    required property int selectedIndex

    readonly property bool selected: root.index === root.selectedIndex

    signal selectRequested
    signal activated

    // Best-effort nicer name for the nameplate -- window data only has
    // the raw appid (e.g. "kitty", "org.vinegarhq.Sober"), so this tries
    // to match it against an installed .desktop id (checked on this
    // system: kitty.desktop/discord.desktop match their appid exactly)
    // and falls back to the appid itself when nothing matches. Spec
    // gives no resolution method for this, just "App-Name in
    // GROSSBUCHSTABEN".
    function _appName(appid) {
        if (!appid)
            return "?";
        const needle = appid.toLowerCase();
        const match = DesktopEntries.applications.values.find(e => (e.id || "").toLowerCase().replace(/\.desktop$/, "") === needle);
        return match ? (match.name || appid) : appid;
    }
    readonly property string _appDisplayName: root._appName(root.modelData.appid)

    width: root.selected ? Style.sliceExpandedWidth : Style.sliceWidth
    height: Style.sliceHeight
    Behavior on width {
        NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
    }

    // No hover-based z-bump -- spec's switcher "Steuerung" bullet has no
    // mouse-hover-selects rule like the launcher's, so there's no hover
    // tier to rank above the distance falloff.
    readonly property int _distance: Math.abs(root.index - root.selectedIndex)
    z: root.selected ? 100 : 50 - root._distance

    // Rand-Fade: spec gives one distance (1.5 x sliceWidth) and an eased
    // duration, not a start/end pair like the launcher's normalized-
    // distance fade -- read literally as "fades out over that distance
    // once past the visible card edge", since this card (unlike the
    // launcher's, which is exactly as wide as its own content) is a
    // fixed 1600px clip on a wider list.
    readonly property real _distPastEdge: {
        const view = root.ListView.view;
        if (!view)
            return 0;
        const centerX = root.x + root.width / 2;
        const viewCenterX = view.contentX + view.width / 2;
        return Math.max(0, Math.abs(centerX - viewCenterX) - Style.switcherCardWidth / 2);
    }
    readonly property real _fadeSpan: 1.5 * Style.sliceWidth
    opacity: root._distPastEdge <= 0 ? 1 : Math.max(0, 1 - root._distPastEdge / root._fadeSpan)
    Behavior on opacity {
        NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
    }

    function _points(w, h, s) {
        return [[s, 0], [w, 0], [w - s, h], [0, h]];
    }

    // -- Shadow: three stacked parallelogram copies (spec: offsets
    // x1/x0.6/x1.4, alpha x0.5/x0.3/x0.2 over a base offset/alpha that
    // itself depends on selection).
    readonly property real _shadowBaseX: root.selected ? 4 : 2
    readonly property real _shadowBaseY: root.selected ? 10 : 5
    readonly property real _shadowBaseAlpha: root.selected ? 0.6 : 0.4

    Canvas {
        id: shadowLayer1
        width: root.width
        height: root.height
        x: root._shadowBaseX * 1.0
        y: root._shadowBaseY * 1.0
        property real shapeOpacity: root._shadowBaseAlpha * 0.5
        Behavior on x { NumberAnimation { duration: Style.animNormal } }
        Behavior on y { NumberAnimation { duration: Style.animNormal } }
        Behavior on shapeOpacity { NumberAnimation { duration: Style.animNormal } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onShapeOpacityChanged: requestPaint()
        onPaint: root._paintShadow(getContext("2d"), width, height, shapeOpacity)
    }
    Canvas {
        id: shadowLayer2
        width: root.width
        height: root.height
        x: root._shadowBaseX * 0.6
        y: root._shadowBaseY * 0.6
        property real shapeOpacity: root._shadowBaseAlpha * 0.3
        Behavior on x { NumberAnimation { duration: Style.animNormal } }
        Behavior on y { NumberAnimation { duration: Style.animNormal } }
        Behavior on shapeOpacity { NumberAnimation { duration: Style.animNormal } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onShapeOpacityChanged: requestPaint()
        onPaint: root._paintShadow(getContext("2d"), width, height, shapeOpacity)
    }
    Canvas {
        id: shadowLayer3
        width: root.width
        height: root.height
        x: root._shadowBaseX * 1.4
        y: root._shadowBaseY * 1.4
        property real shapeOpacity: root._shadowBaseAlpha * 0.2
        Behavior on x { NumberAnimation { duration: Style.animNormal } }
        Behavior on y { NumberAnimation { duration: Style.animNormal } }
        Behavior on shapeOpacity { NumberAnimation { duration: Style.animNormal } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onShapeOpacityChanged: requestPaint()
        onPaint: root._paintShadow(getContext("2d"), width, height, shapeOpacity)
    }
    function _paintShadow(ctx, w, h, alpha) {
        ctx.reset();
        const pts = root._points(w, h, Math.min(Style.sliceSkew, w / 2));
        ctx.beginPath();
        ctx.moveTo(pts[0][0], pts[0][1]);
        for (let i = 1; i < pts.length; i++)
            ctx.lineTo(pts[i][0], pts[i][1]);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(0, 0, 0, alpha);
        ctx.fill();
    }

    // -- Masked content: gradient background + icon/glyph + darken
    // overlay, clipped to the parallelogram in one pass, same MultiEffect
    // mask idiom as SliceDelegate.qml.
    Item {
        id: content
        anchors.fill: parent
        visible: false

        // Spec: "vertikaler Verlauf von surfaceContainer nach surface
        // statt Bild" -- replaces the launcher's background image.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Colors.surfaceContainer }
                GradientStop { position: 1.0; color: Colors.surface }
            }
        }

        // Icon 96px, 20px above center (spec).
        IconImage {
            id: iconImg
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            implicitSize: 96
            source: Quickshell.hasThemeIcon(root.modelData.appid) ? Quickshell.iconPath(root.modelData.appid) : ""
            visible: status === Image.Ready
        }

        // Glyph fallback: color animates selected->primary, else
        // tertiary@0.5 (spec), 200ms.
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            visible: !iconImg.visible
            text: root._appDisplayName.trim().charAt(0).toUpperCase()
            font.family: Style.textFont
            font.pixelSize: 48
            font.bold: true
            color: root.selected ? Colors.primary : Colors.tertiary
            opacity: root.selected ? 1 : 0.5
            Behavior on color { ColorAnimation { duration: Style.animNormal } }
            Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
        }

        // Darken: 0.4 -> 0 on selection (spec gives only these two states
        // here, unlike the launcher's three-state hover version).
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.selected ? 0 : 0.4
            Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
        }
    }

    Canvas {
        id: shapeMask
        anchors.fill: content
        visible: false
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pts = root._points(width, height, Math.min(Style.sliceSkew, width / 2));
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++)
                ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();
            ctx.fillStyle = "white";
            ctx.fill();
        }
    }

    MultiEffect {
        anchors.fill: content
        source: content
        maskEnabled: true
        maskSource: shapeMask
        maskThresholdMin: 0.3
        maskSpreadAtMin: 0.3
    }

    // -- Border: selected 3px primary, else 1px black@0.6 (spec gives
    // only these two states here, unlike the launcher's three-state
    // hover version).
    Canvas {
        id: borderCanvas
        anchors.fill: parent
        property color strokeColor: root.selected ? Colors.primary : Qt.rgba(0, 0, 0, 0.6)
        property real strokeWidth: root.selected ? 3 : 1
        onStrokeColorChanged: requestPaint()
        onStrokeWidthChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pts = root._points(width, height, Math.min(Style.sliceSkew, width / 2));
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i <= pts.length; i++)
                ctx.lineTo(pts[i % pts.length][0], pts[i % pts.length][1]);
            ctx.closePath();
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = strokeWidth;
            ctx.stroke();
        }
    }

    // -- Badges. Generic style per spec: rgba(0,0,0,0.75) fill, 1px
    // primary@0.4 border, 9px bold text, letterSpacing 0.5 -- FOCUSED is
    // the one explicit exception ("in primary mit primaryText").
    Rectangle {
        id: focusedBadge
        visible: !!root.modelData.is_focused
        x: Math.min(Style.sliceSkew, root.width / 2) + 6
        y: 10
        height: 20
        radius: 10
        color: Colors.primary
        width: focusedLabel.implicitWidth + 16
        Text {
            id: focusedLabel
            anchors.centerIn: parent
            text: "FOCUSED"
            font.family: Style.textFont
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.5
            color: Colors.primaryText
        }
    }

    Rectangle {
        id: wsBadge
        visible: (root.modelData.tags || []).length > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 10
        anchors.bottomMargin: 10
        height: 16
        radius: 4
        color: Colors.tertiary
        width: wsLabel.implicitWidth + 12
        Text {
            id: wsLabel
            anchors.centerIn: parent
            text: "WS " + ((root.modelData.tags || [])[0] || "")
            font.family: Style.textFont
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.5
            // No tertiaryText role exists in Colors.qml -- surface (a
            // dark tone in both the fallback and matugen palettes) reads
            // over the lighter tertiary fill, judgment call.
            color: Colors.surface
        }
    }

    Rectangle {
        id: floatBadge
        visible: !!root.modelData.is_floating
        // 10px inset, not skew-based: unlike the top-left FOCUSED badge,
        // the parallelogram's left boundary already sits at x=0 down
        // here near the bottom edge (see _points()), so this just
        // mirrors wsBadge's 10px right-bottom margin for symmetry --
        // spec gives no number for this badge's position.
        x: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
        width: floatLabel.implicitWidth + 16
        Text {
            id: floatLabel
            anchors.centerIn: parent
            text: "FLOAT"
            font.family: Style.textFont
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 0.5
            color: Colors.primaryText
        }
    }

    // -- Nameplate: only when selected (not hover -- switcher has no
    // hover concept), 40px above the bottom edge.
    Rectangle {
        id: nameplate
        visible: root.selected
        opacity: root.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
        width: Math.max(nameLabel.implicitWidth, titleLabel.implicitWidth) + 24
        height: nameCol.implicitHeight + 16

        Column {
            id: nameCol
            anchors.centerIn: parent
            spacing: 2
            Text {
                id: nameLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: root._appDisplayName.toUpperCase()
                font.family: Style.textFont
                font.pixelSize: 13
                font.bold: true
                color: Colors.primary
            }
            Text {
                id: titleLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const t = root.modelData.title || "";
                    return t.length > 60 ? t.slice(0, 60) + "…" : t;
                }
                font.family: Style.textFont
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.6)
            }
        }
    }

    // Same containmentMask limitation as SliceDelegate.qml (this Qt
    // version rejects a QtObject-with-contains() as an Item mask), so
    // the click area is the plain rectangular bounds. No hover-move-
    // select or wheel-scroll here -- spec's switcher "Steuerung" doesn't
    // ask for either, unlike the launcher's.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.selected)
                root.activated();
            else
                root.selectRequested();
        }
    }
}
