import QtQuick
import "../../"
import "../../components"
import "../../services"

// Shared popup shell: night-sky card with stars + grain, a rounded caret
// pointing at the bar button that opened it, and the enter/leave motion
// (fade + 10 px slide + scale from 0.96 with a gentle overshoot).
//
// The content Component is only instantiated while the card is visible
// (Loader), so closed popups cost nothing.
Item {
    id: card

    property string popupId: ""
    property string screenName: ""
    property real screenWidth: 1920
    property real screenHeight: 1080
    property bool centered: false
    property real cardWidth: 380
    property real padding: Theme.s5 - 4
    property int seed: 3
    property Component content

    readonly property bool shown: Popups.isOpen(popupId, screenName)
    readonly property bool caret: !centered && Popups.anchorX >= 0

    // _p drives opacity/slide (smooth), _s drives scale (pops).
    property real _p: shown ? 1 : 0
    property real _s: shown ? 1 : 0.96
    Behavior on _p { NumberAnimation { duration: card.shown ? Theme.tSlow : Theme.tMed; easing.type: Theme.easeOut } }
    Behavior on _s { NumberAnimation { duration: card.shown ? Theme.tPop : Theme.tMed; easing.type: card.shown ? Theme.easePop : Theme.easeOut; easing.overshoot: 1.2 } }

    visible: _p > 0.001
    opacity: _p
    scale: _s
    transformOrigin: centered ? Item.Center : Theme.barTop ? Item.Top : Item.Bottom

    width: cardWidth
    height: loader.item ? loader.item.implicitHeight + padding * 2 : 100

    readonly property real _margin: Theme.barMargin + 4
    // opened via IPC (no anchor) -> centered under the bar
    readonly property real _ax: Popups.anchorX >= 0 ? Popups.anchorX : screenWidth / 2
    x: centered ? (screenWidth - width) / 2 : Math.max(_margin, Math.min(screenWidth - width - _margin, card._ax - width / 2))
    y: centered ? (screenHeight - height) / 2 - screenHeight * 0.06 : Theme.barTop ? Theme.barMargin + Theme.barHeight + Theme.popupGap : screenHeight - Theme.barMargin - Theme.barHeight - Theme.popupGap - height

    transform: Translate { y: (1 - card._p) * (card.centered ? 14 : Theme.barTop ? -10 : 10) }

    Component.onCompleted: Shots.register(popupId + "@" + screenName, card)

    // Eat clicks so they do not reach the dim backdrop behind the card.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: e => e.accepted = true
    }

    // caret: a rounded square turned 45 deg, half hidden behind the card
    Rectangle {
        visible: card.caret
        width: 18
        height: 18
        radius: 5
        rotation: 45
        x: Math.max(Theme.rLarge, Math.min(card.width - Theme.rLarge, card._ax - card.x)) - width / 2
        y: Theme.barTop ? -6 : card.height - height + 6
        color: Theme.mix(Theme.bgTop, Theme.bgMid, Math.max(0, Math.min(1, x / card.width)))
    }

    Backdrop {
        anchors.fill: parent
        radius: Theme.rLarge
        fillAlpha: 0.97
        seed: card.seed
        starCount: Math.round(card.width * card.height / 6000)
        active: card.visible
    }

    Loader {
        id: loader
        x: card.padding
        y: card.padding
        width: card.width - card.padding * 2
        active: card.shown || card._p > 0.001
        sourceComponent: card.content
        focus: true
        onLoaded: item.forceActiveFocus()
    }
    onShownChanged: if (shown && loader.item) loader.item.forceActiveFocus()
}
