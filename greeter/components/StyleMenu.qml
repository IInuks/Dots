import QtQuick
import QtQuick.Effects
import ".."

// Style picker: a carousel of live miniatures of every style. ←/→ (or a
// click on a side card) browses, Enter / a click on the middle card applies,
// Esc / a click outside closes.
Item {
    id: root

    property var ctl: null
    property bool shown: false
    signal closed()

    readonly property real cardW: Math.min(width * 0.44, 760)
    readonly property real cardH: cardW * (height / Math.max(1, width))

    function close() {
        if (!shown) return;
        shown = false;
        closeTimer.restart();
    }
    function apply() {
        ctl.setStyle(Styles.list[view.currentIndex].id);
    }

    Component.onCompleted: {
        view.currentIndex = Math.max(0, Styles.indexOf(ctl.styleId));
        shown = true;
        view.forceActiveFocus();
    }
    Timer {
        id: closeTimer
        interval: Theme.animMid + 60
        onTriggered: root.closed()
    }

    // eats clicks so nothing below reacts; a click on the backdrop closes
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
        onWheel: wheel => wheel.angleDelta.y < 0 ? view.incrementCurrentIndex() : view.decrementCurrentIndex()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgDeep, 0.78)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMid } }
    }

    Column {
        id: heading
        anchors.horizontalCenter: parent.horizontalCenter
        y: view.y - height - Theme.spacingXl + (root.shown ? 0 : -24)
        spacing: Theme.spacingS
        opacity: root.shown ? 1 : 0
        Behavior on y { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMid } }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰏘  Choose a style"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXl
            font.weight: Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "←/→ browse  ·  Enter apply  ·  Esc close"
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
        }
    }

    PathView {
        id: view
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.spacingL + (root.shown ? 0 : 60)
        width: parent.width
        height: root.cardH + 90
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.9
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMid } }
        Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutBack } }

        model: Styles.list
        pathItemCount: Math.min(5, Styles.list.length)
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: 420
        snapMode: PathView.SnapOneItem
        interactive: true
        focus: true

        // centre card big and in front, neighbours smaller and dimmed
        path: Path {
            startX: view.width * 0.5 - root.cardW * 1.55
            startY: view.height / 2
            PathAttribute { name: "itemScale"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathAttribute { name: "itemFade"; value: 0.25 }
            PathLine { x: view.width * 0.5; y: view.height / 2 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 10 }
            PathAttribute { name: "itemFade"; value: 1.0 }
            PathLine { x: view.width * 0.5 + root.cardW * 1.55; y: view.height / 2 }
            PathAttribute { name: "itemScale"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathAttribute { name: "itemFade"; value: 0.25 }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) view.decrementCurrentIndex();
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab) view.incrementCurrentIndex();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.apply();
            else if (event.key === Qt.Key_Escape || (event.key === Qt.Key_S && (event.modifiers & Qt.AltModifier))) root.close();
            else return;
            event.accepted = true;
        }

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool isCurrent: PathView.isCurrentItem
            readonly property bool isActive: modelData.id === root.ctl.styleId

            width: root.cardW
            height: root.cardH + 80
            z: PathView.itemZ ?? 0
            scale: (PathView.itemScale ?? 1) * (hover.hovered && !isCurrent ? 1.04 : 1)
            opacity: PathView.itemFade ?? 1
            Behavior on scale { enabled: hover.hovered; NumberAnimation { duration: Theme.animFast } }

            // staggered pop-in when the menu opens
            transform: Translate { id: intro; y: 40 }
            NumberAnimation {
                running: true
                target: intro; property: "y"; to: 0
                duration: Theme.animSlow + card.index * 60
                easing.type: Easing.OutBack
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (card.isCurrent) root.apply();
                    else view.currentIndex = card.index;
                }
            }

            // -- live miniature (rounded via a mask) ----------------------
            Item {
                id: frame
                width: root.cardW
                height: root.cardH
                visible: false
                Loader {
                    width: root.width
                    height: root.height
                    scale: frame.width / Math.max(1, root.width)
                    transformOrigin: Item.TopLeft
                    enabled: false
                    Component.onCompleted: setSource(Styles.url(card.modelData.id), { ctl: root.ctl, preview: true })
                }
            }
            Rectangle {
                id: mask
                width: frame.width
                height: frame.height
                radius: Theme.radius
                color: "white"
            }
            MultiEffect {
                width: frame.width
                height: frame.height
                source: frame
                maskEnabled: true
                maskSource: ShaderEffectSource { sourceItem: mask; hideSource: true }
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            // border + glow for the selected card
            Rectangle {
                width: frame.width
                height: frame.height
                radius: Theme.radius
                color: "transparent"
                border.width: card.isCurrent ? 2 : 1
                border.color: card.isCurrent ? Theme.accent : Theme.border
                Behavior on border.color { ColorAnimation { duration: Theme.animMid } }
            }
            RectangularShadow {
                z: -1
                width: frame.width
                height: frame.height
                radius: Theme.radius
                blur: 40
                spread: 2
                color: Qt.alpha(card.isCurrent ? Theme.accent : "black", card.isCurrent ? 0.35 : 0.4)
                Behavior on color { ColorAnimation { duration: Theme.animMid } }
            }

            // -- label -----------------------------------------------------
            Column {
                anchors.horizontalCenter: frame.horizontalCenter
                anchors.top: frame.bottom
                anchors.topMargin: Theme.spacingL
                spacing: Theme.spacingXs

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS
                    Text {
                        text: card.modelData.glyph
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontL
                    }
                    Text {
                        text: card.modelData.name
                        color: card.isCurrent ? Theme.text : Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontL
                        font.weight: Font.Medium
                    }
                    Text {
                        visible: card.isActive
                        anchors.verticalCenter: parent.verticalCenter
                        text: "· active"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.modelData.blurb
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                    opacity: card.isCurrent ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animMid } }
                }
            }
        }
    }

    // page dots
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: view.bottom
        anchors.topMargin: Theme.spacingL
        spacing: Theme.spacingS
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMid } }
        Repeater {
            model: Styles.list.length
            Rectangle {
                required property int index
                height: 6
                width: index === view.currentIndex ? 22 : 6
                radius: 3
                color: index === view.currentIndex ? Theme.accent : Theme.textFaint
                Behavior on width { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animMid } }
            }
        }
    }
}
