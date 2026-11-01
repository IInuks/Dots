import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../"

// Menus-prompt section 2, "Ein Streifen (SliceDelegate)": one skewed,
// overlapping parallelogram in the launcher's slice list. Corner rounding
// (spec's optional `roundCorners`/`cornerRadius`) is NOT built -- the
// spec's own default is "aus" (off), same "ship the default, defer the
// optional extra" call the pill bar-style and launcher hex/grid modes
// already make elsewhere in this project (see README "Noch nicht gebaut").
Item {
    id: root

    required property var modelData // {entry, id, name, icon, isGame, isSteam, steamAppId}
    required property int index
    required property int selectedIndex

    readonly property bool selected: root.index === root.selectedIndex

    signal selectRequested
    signal activated

    readonly property bool _hovered: mouseArea.containsMouse

    width: root.selected ? Style.sliceExpandedWidth : Style.sliceWidth
    height: Style.sliceHeight
    Behavior on width {
        NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
    }

    // z-order: selected on top, hovered just under it, everything else
    // falls off with distance from the selected index (spec: "50 -
    // Abstand zum ausgewählten Index").
    readonly property int _distance: Math.abs(root.index - root.selectedIndex)
    z: root.selected ? 100 : (root._hovered ? 90 : 50 - root._distance)

    // Rand-Fade: normalized distance of this delegate's center from the
    // ListView viewport's center, using the shared ListView.view attached
    // property so it re-evaluates as the list scrolls (contentX changes).
    readonly property real _normDist: {
        const view = root.ListView.view;
        if (!view || view.width <= 0)
            return 0;
        const centerX = root.x + root.width / 2;
        const viewCenterX = view.contentX + view.width / 2;
        return Math.abs(centerX - viewCenterX) / (view.width / 2);
    }
    opacity: root._normDist <= 0.6 ? 1 : (root._normDist >= 1.2 ? 0 : 1 - (root._normDist - 0.6) / 0.6)

    function _points(w, h, s) {
        return [[s, 0], [w, 0], [w - s, h], [0, h]];
    }

    // -- Shadow: a plain offset+alpha copy of the shape, drawn behind
    // everything else, per spec ("schwarze Kopie der Form dahinter").
    Canvas {
        id: shadowCanvas
        width: root.width
        height: root.height
        x: root.selected ? 4 : 2
        y: root.selected ? 10 : 5
        property real shapeOpacity: root.selected ? 0.5 : 0.3
        Behavior on x { NumberAnimation { duration: Style.animNormal } }
        Behavior on y { NumberAnimation { duration: Style.animNormal } }
        Behavior on shapeOpacity { NumberAnimation { duration: Style.animNormal } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onShapeOpacityChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pts = root._points(width, height, Math.min(Style.sliceSkew, width / 2));
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++)
                ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(0, 0, 0, shapeOpacity);
            ctx.fill();
        }
    }

    // -- Masked content: background image / icon / glyph + darken overlay,
    // all clipped to the parallelogram in one pass (spec: "Bild und
    // Farbfläche werden mit MultiEffect-Maske ... beschnitten").
    Item {
        id: content
        anchors.fill: parent
        // Kept out of normal painting -- MultiEffect below still captures
        // it as a texture source via `source`/`maskSource` even though
        // it's invisible (documented QtQuick.Effects behavior), so the
        // unmasked rectangle never bleeds through outside the parallelogram.
        visible: false

        readonly property string _artwork: AppIndex.artworkPath(root.modelData)

        Image {
            id: bgImage
            anchors.fill: parent
            source: content._artwork
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: content._artwork !== "" && status === Image.Ready
        }

        Rectangle {
            id: iconFallback
            anchors.fill: parent
            visible: !bgImage.visible
            color: Colors.surfaceVariant
            opacity: 0.8

            IconImage {
                id: iconImg
                anchors.centerIn: parent
                implicitSize: 72
                source: root.modelData.icon !== "" ? Quickshell.iconPath(root.modelData.icon, "application-x-executable") : ""
                visible: status === Image.Ready
            }

            // Glyph fallback (spec: "sonst ein Glyph in 48px primary@0.7"):
            // first letter of the app name -- the spec gives no glyph
            // content, just size/color, so this is a judgment call.
            Text {
                anchors.centerIn: parent
                visible: !iconImg.visible
                text: (root.modelData.name || "?").trim().charAt(0).toUpperCase()
                font.family: Style.textFont
                font.pixelSize: 48
                font.bold: true
                color: Colors.primary
                opacity: 0.7
            }
        }

        Rectangle {
            id: darken
            anchors.fill: parent
            color: "black"
            opacity: root.selected ? 0 : (root._hovered ? 0.15 : 0.4)
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

    // -- Border, drawn on top of the masked content (spec: selected 3px
    // primary, hover 1px primary (halbtransparent), else 1px rgba(0,0,0,0.6)).
    Canvas {
        id: borderCanvas
        anchors.fill: parent
        property color strokeColor: root.selected ? Colors.primary : (root._hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5) : Qt.rgba(0, 0, 0, 0.6))
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

    // -- Namensschild: pill badge, 16px above the bottom edge, centered.
    Rectangle {
        id: nameplate
        visible: opacity > 0
        opacity: (root.selected || root._hovered) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        height: 22
        radius: 11
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
        width: nameLabel.implicitWidth + 20

        Text {
            id: nameLabel
            anchors.centerIn: parent
            text: (root.modelData.name || "").toUpperCase()
            font.family: Style.textFont
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 0.5
            color: Colors.tertiary
        }
    }

    // Spec: "Auch die Klickfläche folgt exakt der Schräge (containmentMask)"
    // -- attempted via a QtObject exposing contains(point), but this Qt
    // version rejects it at runtime ("Object set as mask does not have an
    // invokable contains method"), so the click/hover area falls back to
    // the plain rectangular bounds below. The visible dead corners are
    // sliceSkew (35px) triangles at two corners of each 135px+ wide slice
    // -- small, and mostly covered by the neighboring higher-z slice's
    // overlap anyway (spacing -22px) -- so this is a minor, not a visible,
    // deviation. See README "Noch nicht gebaut".
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property point _enterPos: Qt.point(0, 0)
        property bool _passedThreshold: false

        onEntered: {
            _enterPos = Qt.point(mouseX, mouseY);
            _passedThreshold = false;
        }
        onPositionChanged: mouse => {
            if (_passedThreshold)
                return;
            const dx = mouse.x - _enterPos.x;
            const dy = mouse.y - _enterPos.y;
            if (Math.hypot(dx, dy) > 2) {
                _passedThreshold = true;
                root.selectRequested();
            }
        }
        onClicked: {
            if (root.selected)
                root.activated();
            else
                root.selectRequested();
        }
    }
}
