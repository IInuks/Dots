import QtQuick
import QtQuick.Effects

// Angelehnt an quickdots/bars/ricev2/Bar/launcher/SliceDelegate.qml: ein
// schraeges, ueberlappendes Parallelogramm, das beim Auswaehlen aufklappt.
// Eckenradius bleibt wie dort ungebaut (Spec-Default "aus"), und das
// containmentMask-Problem ist identisch: ein QtObject mit contains(point)
// wird von dieser Qt-Version als Item.containmentMask zur Laufzeit
// abgelehnt ("Object set as mask does not have an invokable contains
// method"), daher bleibt die Klickflaeche rechteckig -- die toten Ecken
// (je sliceSkew=35px) sind meist vom hoeher-z-liegenden Nachbar-Slice
// ueberdeckt (Overlap sliceSpacing=-22px).
Item {
    id: root

    required property string modelData // Wallpaper-Pfad
    required property var config
    required property var appState
    required property int index
    required property int selectedIndex

    readonly property bool selected: root.index === root.selectedIndex

    signal selectRequested
    signal activated

    readonly property bool _hovered: mouseArea.containsMouse

    width: root.selected ? config.sliceExpandedWidth : config.sliceWidth
    height: config.sliceHeight
    Behavior on width {
        NumberAnimation { duration: config.animExpand; easing.type: Easing.OutCubic }
    }

    // z-Order: ausgewaehltes Slice obenauf, gehovertes knapp darunter,
    // alles andere faellt mit Abstand zum ausgewaehlten Index ab.
    readonly property int _distance: Math.abs(root.index - root.selectedIndex)
    z: root.selected ? 100 : (root._hovered ? 90 : 50 - root._distance)

    // Rand-Fade: normierter Abstand dieses Delegates zum Viewport-Zentrum,
    // reaktiv ueber die ListView.view-Attached-Property (aktualisiert sich
    // beim Scrollen automatisch mit).
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

    // -- Schatten: schwarze Kopie der Form dahinter, versetzt.
    Canvas {
        id: shadowCanvas
        width: root.width
        height: root.height
        x: root.selected ? 4 : 2
        y: root.selected ? 10 : 5
        property real shapeOpacity: root.selected ? 0.5 : 0.3
        Behavior on x { NumberAnimation { duration: config.animNormal } }
        Behavior on y { NumberAnimation { duration: config.animNormal } }
        Behavior on shapeOpacity { NumberAnimation { duration: config.animNormal } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onShapeOpacityChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pts = root._points(width, height, Math.min(config.sliceSkew, width / 2));
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++)
                ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(0, 0, 0, shapeOpacity);
            ctx.fill();
        }
    }

    // -- Maskierter Inhalt: Wallpaper-Thumbnail + Abdunkelung, in einem
    // Durchgang auf das Parallelogramm beschnitten.
    Item {
        id: content
        anchors.fill: parent
        // Bleibt unsichtbar -- MultiEffect greift es trotzdem als Textur
        // via source/maskSource ab (dokumentiertes QtQuick.Effects-
        // Verhalten), sonst wuerde das unmaskierte Rechteck aussen
        // durchscheinen.
        visible: false

        Image {
            id: thumb
            anchors.fill: parent
            source: "file://" + root.modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: config.thumbSourceWidth
            sourceSize.height: config.thumbSourceHeight
        }

        Rectangle {
            anchors.fill: parent
            visible: thumb.status !== Image.Ready
            color: config.surfaceContainer
        }

        Rectangle {
            id: darken
            anchors.fill: parent
            color: "black"
            opacity: root.selected ? 0 : (root._hovered ? 0.15 : 0.4)
            Behavior on opacity { NumberAnimation { duration: config.animNormal } }
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
            const pts = root._points(width, height, Math.min(config.sliceSkew, width / 2));
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

    // -- Rand: ausgewaehlt 3px primary, Hover 1px primary (halbtransparent),
    // sonst 1px rgba(0,0,0,0.6).
    Canvas {
        id: borderCanvas
        anchors.fill: parent
        property color strokeColor: root.selected ? config.primary : (root._hovered ? Qt.rgba(config.primary.r, config.primary.g, config.primary.b, 0.5) : Qt.rgba(0, 0, 0, 0.6))
        property real strokeWidth: root.selected ? 3 : 1
        onStrokeColorChanged: requestPaint()
        onStrokeWidthChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pts = root._points(width, height, Math.min(config.sliceSkew, width / 2));
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

    // -- Namensschild: Pill-Badge, 16px ueber der Unterkante, zentriert.
    // Zeigt Dateiname + (sobald geladen) die per identify aufgeloeste
    // Bildaufloesung -- einzige inhaltliche Ergaenzung gegenueber dem
    // Launcher-Vorbild, das hier nur den App-Namen zeigt.
    Rectangle {
        id: nameplate
        visible: opacity > 0
        opacity: (root.selected || root._hovered) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: config.animFast } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        height: 22
        radius: 11
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(config.primary.r, config.primary.g, config.primary.b, 0.4)
        width: nameLabel.implicitWidth + 20

        Text {
            id: nameLabel
            anchors.centerIn: parent
            text: {
                const name = root.modelData.substring(root.modelData.lastIndexOf("/") + 1).toUpperCase();
                const res = root.appState.resolutionFor(root.modelData);
                return res ? name + "  ·  " + res : name;
            }
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 0.5
            color: config.tertiary
        }
    }

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
