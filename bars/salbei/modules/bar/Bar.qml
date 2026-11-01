import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../"
import "../../components"
import "../../services"

// Floating centered pill: launcher + tags + stats | clock | status + buttons.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors.top: true
    margins.top: Theme.barMargin
    implicitWidth: Math.round(modelData.width * Theme.barWidthFraction)
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + Theme.barMargin
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top

    // same glass as the popups (hairline), fully rounded, but a flat green tint (no plum end)
    GlassSurface {
        id: pill
        anchors.fill: parent
        radius: height / 2
        toColor: Theme.panelFrom

        // ── startup: the pill drops in and stretches open, then the clusters follow ──
        property real intro: 0
        property real left_: 0
        property real center_: 0
        property real right_: 0
        opacity: intro
        transform: [
            Scale { origin.x: pill.width / 2; origin.y: 0; xScale: 0.55 + 0.45 * pill.intro; yScale: 0.7 + 0.3 * pill.intro },
            Translate { y: (1 - pill.intro) * -12 }
        ]
        SequentialAnimation {
            running: true
            PauseAnimation { duration: 150 }
            NumberAnimation { target: pill; property: "intro"; to: 1; duration: 650; easing.type: Theme.easingSpring; easing.overshoot: 1.3 }
        }
        SequentialAnimation {
            running: true
            PauseAnimation { duration: 450 }
            ParallelAnimation {
                NumberAnimation { target: pill; property: "center_"; to: 1; duration: 500; easing.type: Theme.easingEmph }
                SequentialAnimation {
                    PauseAnimation { duration: 90 }
                    ParallelAnimation {
                        NumberAnimation { target: pill; property: "left_"; to: 1; duration: 550; easing.type: Theme.easingEmph }
                        NumberAnimation { target: pill; property: "right_"; to: 1; duration: 550; easing.type: Theme.easingEmph }
                    }
                }
            }
        }

        // left
        RowLayout {
            opacity: pill.left_
            transform: Translate { x: (1 - pill.left_) * 24 }
            anchors.left: parent.left
            anchors.leftMargin: Theme.barPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barSpacing

            IconButton {
                icon: "apps"
                filled: false
                round: true
                implicitWidth: 24
                implicitHeight: 24
                iconColor: Ui.launcherOpen ? Theme.accent : Theme.text
                iconItem.rotation: Ui.launcherOpen ? 90 : 0
                iconItem.animateChange: false
                Behavior on iconItem.rotation { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 2 } }
                onClicked: Ui.toggleLauncher()
                onRightClicked: Ui.toggleControlCenter("home")
            }
            TagStrip { monitor: bar.modelData.name }
            StatsCluster {}
        }

        // center
        ClockLabel {
            anchors.centerIn: parent
            opacity: pill.center_
            scale: 0.8 + 0.2 * pill.center_
        }

        // right
        RowLayout {
            opacity: pill.right_
            transform: Translate { x: (1 - pill.right_) * -24 }
            anchors.right: parent.right
            anchors.rightMargin: Theme.barPadding - 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barSpacing

            StatusCluster {}
            ButtonCluster { barWindow: bar }
        }
    }
}
