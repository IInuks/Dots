import QtQuick

// Rahmen für jedes Menü: hängt unter seinem Leisten-Knopf (oder mittig),
// ploppt mit leichtem Überschwingen auf und zieht sich beim Schließen
// wieder zum Knopf zurück.
Item {
    id: card
    property string popupId: ""
    property string screenName: ""
    property real screenWidth: 0
    property bool centered: false
    property real padding: 18
    default property alias content: inner.data
    readonly property bool shown: Ui.openId === popupId && Ui.screenName === screenName

    width: 360
    height: inner.childrenRect.height + padding * 2
    x: {
        if (centered || Ui.anchorX < 0) return (screenWidth - width) / 2;
        return Math.max(Theme.gap + 4, Math.min(screenWidth - width - Theme.gap - 4, Ui.anchorX - width / 2));
    }
    y: centered ? 140 : Theme.barHeight + Theme.gap * 2 + 6

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: card.shown ? Theme.tMed : Theme.tFast } }
    Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: card.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.6 } }
    transform: Translate { y: card.shown ? 0 : -14; Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } } }

    Component.onCompleted: Shots.register(popupId + "@" + screenName, card)

    // Schatten (zwei weiche Lagen reichen)
    Rectangle { anchors.fill: bg; anchors.margins: -6; anchors.topMargin: 2; radius: bg.radius + 6; color: Theme.alpha("#000000", 0.12) }
    Rectangle { anchors.fill: bg; anchors.margins: -2; anchors.topMargin: 4; radius: bg.radius + 2; color: Theme.alpha("#000000", 0.18) }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.max(12, Theme.radius + 4)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line
        // Akzentschimmer oben
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 1
            height: 80
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.alpha(Theme.accent, 0.10) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        // Klicks auf die Karte schließen nicht
        MouseArea { anchors.fill: parent }
    }

    Item {
        id: inner
        x: card.padding; y: card.padding
        width: card.width - card.padding * 2
        height: childrenRect.height
    }
}
