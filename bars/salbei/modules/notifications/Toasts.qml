import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../"
import "../../components"
import "../../services"

// Toast stack top-right under the bar. The window only exists while toasts are shown.
PanelWindow {
    id: win

    anchors { top: true; right: true }
    margins.top: Theme.grid
    margins.right: Theme.grid * 2
    implicitWidth: Theme.toastWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    visible: Notifs.toasts.length > 0
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        width: parent.width
        spacing: Theme.grid
        // remaining toasts glide up when one leaves
        move: Transition {
            NumberAnimation { properties: "y"; duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 1.1 }
        }

        Repeater {
            // keyed model: existing toasts keep their delegate (and countdown) when others come and go
            model: ScriptModel { values: Notifs.toasts; objectProp: "key" }

            Item {
                id: toast
                required property var modelData
                width: stack.width
                height: card.height * Math.min(1, shown * 1.5)
                clip: leaving

                property real shown: 0
                property bool leaving: false
                Component.onCompleted: enter.start()
                ParallelAnimation {
                    id: enter
                    NumberAnimation { target: toast; property: "shown"; to: 1; duration: 520; easing.type: Theme.easingSpring; easing.overshoot: 1.3 }
                    SequentialAnimation {
                        PauseAnimation { duration: 140 }
                        NumberAnimation { target: icon; property: "scale"; from: 0; to: 1; duration: 450; easing.type: Theme.easingSpring; easing.overshoot: 2.5 }
                    }
                }
                function leave() {
                    if (leaving) return;
                    leaving = true;
                    exit.start();
                }
                SequentialAnimation {
                    id: exit
                    NumberAnimation { target: toast; property: "shown"; to: 0; duration: 260; easing.type: Easing.InCubic }
                    ScriptAction { script: Notifs.dismissToast(toast.modelData.key) }
                }

                GlassSurface {
                    id: card
                    width: parent.width
                    height: row.implicitHeight + 28
                    radius: Theme.radiusTile
                    opacity: Math.min(1, toast.shown)
                    x: (1 - toast.shown) * (toast.leaving ? Theme.toastWidth * 0.6 : 60)
                    property real hoverScale: hover.containsMouse ? 1.025 : 1
                    Behavior on hoverScale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
                    scale: (0.9 + 0.1 * Math.min(1, toast.shown)) * hoverScale
                    transformOrigin: Item.Right

                    RowLayout {
                        id: row
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 12

                        AppIcon {
                            id: icon
                            Layout.alignment: Qt.AlignTop
                            size: 32
                            icon: toast.modelData.image || toast.modelData.appIcon
                            fallbackText: toast.modelData.appName
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Txt {
                                Layout.fillWidth: true
                                text: toast.modelData.summary
                                font.pixelSize: Theme.fontItem
                                font.weight: Font.Bold
                            }
                            Txt {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: toast.modelData.body
                                color: Theme.textDim
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.Normal
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                            }
                        }
                    }

                    // accent progress hairline at the bottom
                    Rectangle {
                        id: progress
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        x: Theme.radiusTile
                        height: 2
                        radius: 1
                        color: Theme.accent
                        width: (card.width - 2 * Theme.radiusTile) * ratio
                        property real ratio: 1
                        NumberAnimation on ratio {
                            id: countdown
                            from: 1
                            to: 0
                            duration: toast.modelData.timeout
                            running: !hover.containsMouse
                            onFinished: toast.leave()
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: e => {
                            if (e.button === Qt.LeftButton) {
                                Ui.closeAll();
                                Ui.ccPage = "notifications";
                                Ui.controlCenterOpen = true;
                            }
                            toast.leave();
                        }
                    }
                }
            }
        }
    }
}
