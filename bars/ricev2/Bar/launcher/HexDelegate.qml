import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../"

// Menus-prompt section 2, "Alternative Modi" -> "hex": one flat-top hexagon
// in the launcher's honeycomb layout. Content treatment (image/icon/glyph,
// darken, border, nameplate) mirrors SliceDelegate.qml -- the spec only
// redefines shape/geometry for this mode ("Waben mit Radius 140, ...
// Übergänge wie oben"), so the per-item look is read as carried over from
// the canonical "Ein Streifen" description rather than reinvented.
//
// Self-positions from its own `index` (row-major fill: row = index /
// hexCols, col = index % hexCols) rather than being placed by a ListView/
// GridView, since QtQuick has no built-in view that lays out a staggered,
// arc-bowed honeycomb. That also means this delegate, unlike SliceDelegate,
// gets no add/remove/move transitions from a view -- plain Repeater doesn't
// support those. Only the "new item" half is covered (Component.onCompleted
// fade+scale-in below); an item leaving the filtered list just disappears
// instead of fading out. Documented gap, not a guess -- see README "Noch
// nicht gebaut" and grid mode (GridDelegate.qml + a real GridView) getting
// full transition parity because it doesn't need custom positioning.
Item {
    id: root

    required property var modelData
    required property int index
    required property int selectedIndex

    readonly property bool selected: root.index === root.selectedIndex
    readonly property int _col: root.index % Style.hexCols
    readonly property int _row: Math.floor(root.index / Style.hexCols)

    signal selectRequested
    signal activated

    readonly property bool _hovered: mouseArea.containsMouse

    x: root._col * Style.hexStepX
    y: root._row * (Style.hexHeight + Style.hexSpacing) + Style.hexArcOffset(root._col)
    width: Style.hexWidth
    height: Style.hexHeight

    z: root.selected ? 100 : (root._hovered ? 90 : 10)

    opacity: 0
    scale: 0.9
    Component.onCompleted: _appear.start()
    ParallelAnimation {
        id: _appear
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: Style.animEnter }
        NumberAnimation { target: root; property: "scale"; from: 0.9; to: 1; duration: Style.animEnter }
    }

    // Flat-top hexagon vertices for a width x height bounding box.
    function _points(w, h) {
        return [[w * 0.25, 0], [w * 0.75, 0], [w, h / 2], [w * 0.75, h], [w * 0.25, h], [0, h / 2]];
    }

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
            const pts = root._points(width, height);
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++)
                ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(0, 0, 0, shapeOpacity);
            ctx.fill();
        }
    }

    Item {
        id: content
        anchors.fill: parent
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
                implicitSize: 56
                source: root.modelData.icon !== "" ? Quickshell.iconPath(root.modelData.icon, "application-x-executable") : ""
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !iconImg.visible
                text: (root.modelData.name || "?").trim().charAt(0).toUpperCase()
                font.family: Style.textFont
                font.pixelSize: 36
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
            const pts = root._points(width, height);
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
            const pts = root._points(width, height);
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

    Rectangle {
        id: nameplate
        visible: opacity > 0
        opacity: (root.selected || root._hovered) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
        width: Math.min(nameLabel.implicitWidth + 16, root.width - 10)

        Text {
            id: nameLabel
            anchors.centerIn: parent
            width: parent.width - 12
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: (root.modelData.name || "").toUpperCase()
            font.family: Style.textFont
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 0.5
            color: Colors.tertiary
        }
    }

    // Same containmentMask limitation as SliceDelegate.qml -- click/hover
    // area falls back to the hexagon's rectangular bounding box, so the
    // four small corner triangles outside the hex are clickable too.
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
