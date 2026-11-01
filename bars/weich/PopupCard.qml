import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// Shared popup shell for Calendar/Volume/Settings. Two-phase close: the
// window itself stays mapped for one more `Theme.animSoft` after `open`
// goes false so the card's fade+scale-out is actually visible -- flipping
// `visible` off immediately would just make the whole layer-shell surface
// vanish mid-animation.
PanelWindow {
    id: win

    default property alias content: column.data
    property string popupId: ""
    property string edge: "right" // "left" | "right" | "center"
    property int popupWidth: 260
    property var targetScreen: null
    readonly property bool open: PopupState.isOpen(popupId)
    property bool _mapped: false

    screen: targetScreen
    visible: _mapped
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "weich-popup-" + popupId
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors {
        top: true
        left: edge !== "right"
        right: edge !== "left"
    }
    // Overlay layer is scoped separately from the Bottom-layer TopReserve and
    // the Top-layer clusters (see TopReserve.qml), so no offset to cancel
    // here -- land directly below the clusters' true bottom edge.
    margins.top: Theme.topReserve + Theme.popupGap
    margins.left: edge === "left" ? Theme.marginSide : 0
    margins.right: edge === "right" ? Theme.marginSide : 0

    implicitWidth: edge === "center" ? (screen ? screen.width : popupWidth) : popupWidth
    implicitHeight: card.implicitHeight + Theme.popupGap

    onOpenChanged: {
        if (open) {
            _closeTimer.stop();
            win._mapped = true;
        } else {
            _closeTimer.restart();
        }
    }
    Timer {
        id: _closeTimer
        interval: Theme.animSoft
        onTriggered: win._mapped = false
    }

    MultiEffect {
        anchors.fill: card
        source: card
        visible: card.opacity > 0.01
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.4)
        shadowBlur: 0.7
        shadowVerticalOffset: 6
        blurMax: 40
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: edge === "center" ? parent.horizontalCenter : undefined
        anchors.left: edge === "left" ? parent.left : undefined
        anchors.right: edge === "right" ? parent.right : undefined
        y: 0
        width: popupWidth
        implicitHeight: column.implicitHeight + Theme.paddingH * 2
        radius: Theme.popupRadius
        color: Theme.paneColor
        border.width: 1
        border.color: Theme.hairline

        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.94
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: Theme.animSoft; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animSoft; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on color { ColorAnimation { duration: Theme.animSoft } }

        Column {
            id: column
            x: Theme.paddingH
            y: Theme.paddingH
            width: parent.width - Theme.paddingH * 2
            spacing: Theme.itemSpacing
        }
    }
}
