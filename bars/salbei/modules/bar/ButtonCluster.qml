import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../"
import "../../components"
import "../../services"

// Bell, tray icons (monochrome), power — small round buttons.
Row {
    id: root

    property var barWindow
    spacing: 4

    IconButton {
        id: bell
        icon: Ui.dnd ? "notifications_off" : "notifications"
        round: true
        filled: false
        implicitWidth: 26
        implicitHeight: 26
        iconColor: Notifs.history.length > 0 && !Ui.dnd ? Theme.accent : Theme.text
        onClicked: Ui.toggleControlCenter("notifications")
        onRightClicked: Ui.dnd = !Ui.dnd

        // ring the bell when a notification arrives
        property int seen: Notifs.history.length
        Connections {
            target: Notifs
            function onHistoryChanged() {
                if (Notifs.history.length > bell.seen && !Ui.dnd) ring.restart();
                bell.seen = Notifs.history.length;
            }
        }
        SequentialAnimation {
            id: ring
            loops: 2
            NumberAnimation { target: bell.iconItem; property: "rotation"; to: 22; duration: 70; easing.type: Easing.OutQuad }
            NumberAnimation { target: bell.iconItem; property: "rotation"; to: -18; duration: 120; easing.type: Easing.InOutQuad }
            NumberAnimation { target: bell.iconItem; property: "rotation"; to: 10; duration: 100; easing.type: Easing.InOutQuad }
            NumberAnimation { target: bell.iconItem; property: "rotation"; to: 0; duration: 140; easing.type: Easing.OutQuad }
        }
        // unread badge
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
            scale: Notifs.history.length > 0 && !Ui.dnd ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
        }
    }

    Repeater {
        model: SystemTray.items.values

        Rectangle {
            id: trayButton
            required property var modelData
            width: 26
            height: 26
            radius: 13
            color: trayMouse.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            // new tray icons pop in
            scale: 0
            Component.onCompleted: scale = Qt.binding(() => trayMouse.pressed ? Theme.pressScale : 1)
            Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 2.5 } }
            rotation: trayMouse.containsMouse ? 8 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }

            IconImage {
                id: trayIcon
                anchors.centerIn: parent
                implicitSize: 15
                source: trayButton.modelData.icon
                visible: false
            }
            MultiEffect {
                anchors.fill: trayIcon
                source: trayIcon
                saturation: -1
                brightness: 0.25
            }
            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    const item = trayButton.modelData;
                    if (e.button === Qt.MiddleButton) item.secondaryActivate();
                    else if (e.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            const p = trayButton.mapToItem(null, 0, trayButton.height + 6);
                            item.display(root.barWindow, p.x, p.y);
                        }
                    } else item.activate();
                }
                onWheel: e => trayButton.modelData.scroll(e.angleDelta.y, false)
            }
        }
    }

    IconButton {
        icon: "power_settings_new"
        round: true
        filled: false
        implicitWidth: 26
        implicitHeight: 26
        iconColor: Ui.powerOpen ? Theme.danger : hovered ? Theme.accent : Theme.text
        iconItem.rotation: hovered || Ui.powerOpen ? 180 : 0
        Behavior on iconItem.rotation { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring } }
        onClicked: Ui.togglePower()
    }
}
