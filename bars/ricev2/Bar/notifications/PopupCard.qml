import QtQuick
import "../../"

// One notification toast (menus prompt section 5). Trapezoid card shape,
// perimeter-stroke draw-on, slide+fade entrance/exit -- everything here is
// per-card; the stack that positions up to Style.popupMaxVisible of these
// lives in PopupHost.qml.
Item {
    id: root

    required property var entry // {id, notif, appName, summary, body, actions, timeoutMs}
    property bool leftSide: false

    readonly property bool hovered: hoverHandler.hovered
    property bool closing: false
    property real remainingMs: entry.timeoutMs > 0 ? entry.timeoutMs : Style.popupDefaultTimeoutMs
    property real strokeProgress: 0

    readonly property int _margin: Style.diagSlant + 4
    readonly property real _fullHeight: contentCol.implicitHeight + 20 // "Margins 10" top+bottom
    property real _closeHeight: root._fullHeight

    height: root.closing ? root._closeHeight : root._fullHeight
    opacity: 0
    x: root.leftSide ? -40 : 40

    function requestClose() {
        if (root.closing)
            return;
        root.closing = true;
        closeAnim.start();
    }

    Component.onCompleted: {
        strokeAnim.start();
        enterAnim.start();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Style.popupEnterMs; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "x"; to: 0; duration: Style.popupEnterMs; easing.type: Easing.OutCubic }
    }

    NumberAnimation {
        id: strokeAnim
        target: root
        property: "strokeProgress"
        from: 0
        to: 1
        duration: Style.popupStrokeMs
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: Style.popupExitMs; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "x"; to: root.leftSide ? -40 : 40; duration: Style.popupExitMs; easing.type: Easing.InCubic }
        }
        // Takes over from _closeHeight's declarative binding to _fullHeight
        // the moment this runs (memory: feedback_qml_animation_on_bound_property)
        // -- intentional here, the delegate is removed from PopupState right
        // after, so nothing ever needs that binding to resume.
        NumberAnimation { target: root; property: "_closeHeight"; to: 0; duration: Style.popupCollapseMs; easing.type: Easing.InOutCubic }
        ScriptAction {
            script: {
                if (root.entry.notif)
                    root.entry.notif.dismiss();
                PopupState.remove(root.entry.id);
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: !root.hovered && !root.closing
        onTriggered: {
            root.remainingMs -= 100;
            if (root.remainingMs <= 0)
                root.requestClose();
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    function _points(w, h, s) {
        return root.leftSide ? [[s, 0], [w, 0], [w - s, h], [0, h]] : [[0, 0], [w - s, 0], [w, h], [s, h]];
    }

    // Declarative-bound properties (not raw Colors.* reads inside onPaint)
    // so Canvas's auto-generated onXChanged actually fires on repaint-worthy
    // changes -- same idiom as Bar/Island.qml's fillColor.
    Canvas {
        id: fillCanvas
        anchors.fill: parent
        property color fillColor: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, Style.notificationAlpha)
        onFillColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const s = Math.min(Style.diagSlant, width / 2);
            const pts = root._points(width, height, s);
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++)
                ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();
        }
    }

    Canvas {
        id: strokeCanvas
        anchors.fill: parent
        property color strokeColor: Colors.primary
        property real progress: root.strokeProgress
        onStrokeColorChanged: requestPaint()
        onProgressChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (progress <= 0)
                return;
            const s = Math.min(Style.diagSlant, width / 2);
            const pts = root._points(width, height, s);
            const edges = [];
            let total = 0;
            for (let i = 0; i < pts.length; i++) {
                const a = pts[i], b = pts[(i + 1) % pts.length];
                const len = Math.hypot(b[0] - a[0], b[1] - a[1]);
                edges.push({ a, b, len });
                total += len;
            }
            let budget = progress * total;
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            for (const e of edges) {
                if (budget <= 0)
                    break;
                ctx.beginPath();
                ctx.moveTo(e.a[0], e.a[1]);
                if (budget >= e.len) {
                    ctx.lineTo(e.b[0], e.b[1]);
                    budget -= e.len;
                } else {
                    const t = e.len > 0 ? budget / e.len : 0;
                    ctx.lineTo(e.a[0] + (e.b[0] - e.a[0]) * t, e.a[1] + (e.b[1] - e.a[1]) * t);
                    budget = 0;
                }
                ctx.stroke();
            }
        }
    }

    // Whole-card click closes it (spec: "Ein Klick auf die Karte schließt
    // sie") -- declared before the header/action MouseAreas below so those
    // sit on top and intercept their own clicks first.
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    Column {
        id: contentCol
        x: root._margin
        y: 10
        width: parent.width - root._margin * 2
        spacing: 4

        Item {
            id: header
            width: parent.width
            height: 16

            Text {
                id: appNameText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.textFont
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Colors.primary
                text: root.entry.appName
            }
            Text {
                id: dotText
                anchors.left: appNameText.right
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.textFont
                font.pixelSize: 12
                color: Colors.outline
                text: "·"
            }
            Text {
                id: closeText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.textFont
                font.pixelSize: 12
                color: closeHover.hovered ? Colors.primary : Colors.outline
                text: "✕"

                HoverHandler { id: closeHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestClose()
                }
            }
            Text {
                anchors.left: dotText.right
                anchors.leftMargin: 6
                anchors.right: closeText.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.textFont
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Colors.tertiary
                elide: Text.ElideRight
                text: root.entry.summary
            }
        }

        Text {
            width: parent.width
            visible: !!root.entry.body
            font.family: Style.textFont
            font.pixelSize: 12
            color: Colors.backgroundText
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            text: root.entry.body || ""
        }

        Row {
            width: parent.width
            visible: (root.entry.actions || []).length > 0
            spacing: 6

            Repeater {
                model: root.entry.actions || []

                Rectangle {
                    id: actionBtn
                    required property var modelData
                    height: 22
                    radius: 11
                    width: actionLabel.implicitWidth + 20
                    color: actionHover.hovered ? Colors.primary : Qt.rgba(Colors.secondaryContainer.r, Colors.secondaryContainer.g, Colors.secondaryContainer.b, 0.5)

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        font.family: Style.textFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: actionHover.hovered ? Colors.primaryText : Colors.tertiary
                        text: actionBtn.modelData.text
                    }

                    HoverHandler { id: actionHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionBtn.modelData.invoke()
                    }
                }
            }
        }
    }
}
