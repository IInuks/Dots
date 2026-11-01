import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"
import "../../components"
import "../../services"

// Floating, detached capsule bar (one per screen).
//
//   capsule mode:  one long night-sky capsule, sections sit inside it
//   islands mode:  three separate floating capsules (left/center/right)
//
// The window spans the full screen width so item x == screen x (popups use
// that to aim their caret); only the capsule area takes input (mask).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property string screenName: modelData.name

    anchors {
        top: Theme.barTop
        bottom: !Theme.barTop
        left: true
        right: true
    }
    // Window height MUST equal the exclusive zone: mango shifts a layer
    // surface that is taller than its exclusive zone towards the screen edge
    // by the difference, which pushed the capsule partly off-screen. So no
    // extra room below for the drop shadow (it is only visible above/sides).
    implicitHeight: Theme.barMargin + Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "kurtz-bar"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: area }

    // Popups call this to find where to point their caret.
    function openAt(id, item) {
        const p = item.mapToItem(null, item.width / 2, 0);
        Popups.toggle(id, win.screenName, p.x);
    }

    Item {
        id: area
        x: Theme.barMargin
        y: Theme.barTop ? Theme.barMargin : win.height - Theme.barMargin - Theme.barHeight
        width: win.width - Theme.barMargin * 2
        height: Theme.barHeight

        // Entrance: the capsule drops in from its edge on startup.
        opacity: 0
        transform: Translate { id: enter; y: Theme.barTop ? -24 : 24 }
        Component.onCompleted: {
            intro.start();
            Shots.register("bar@" + win.screenName, area);
        }
        ParallelAnimation {
            id: intro
            NumberAnimation { target: area; property: "opacity"; to: 1; duration: Theme.tSlow * 2; easing.type: Theme.easeOut }
            NumberAnimation { target: enter; property: "y"; to: 0; duration: Theme.tPop * 2; easing.type: Theme.easePop; easing.overshoot: 1.2 }
        }

        Backdrop {
            anchors.fill: parent
            visible: !Theme.islands
            radius: height / 2
            fillAlpha: Theme.c.barAlpha
            starCount: Math.round(Theme.c.starCount * 0.9)
            seed: 7
            sparkles: false
            twinkle: Theme.c.barTwinkle
        }

        // ---------------------------------------------------------- left
        Section {
            id: left
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            seed: 11

            LauncherButton {
                visible: Theme.c.showLauncher
                onClicked: win.openAt("launcher", this)
            }
            Workspaces {
                screenName: win.screenName
            }
            WindowTitle {
                visible: Theme.c.showTitle && text !== ""
                text: Tags.title(win.screenName)
                appId: Tags.appId(win.screenName)
            }
        }

        // -------------------------------------------------------- center
        Section {
            id: center
            anchors.centerIn: parent
            seed: 12

            ClockPill {
                id: clockPill
                onClicked: win.openAt("calendar", clockPill)
            }
        }

        // --------------------------------------------------------- right
        Section {
            id: right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            seed: 13

            MediaPill {
                id: mediaPill
                visible: Theme.c.showMedia && Player.present
                onOpen: win.openAt("media", mediaPill)
            }
            StatsPill {
                id: statsPill
                visible: Theme.c.showStats
                onClicked: win.openAt("system", statsPill)
            }
            TrayPill {
                visible: Theme.c.showTray && count > 0
                hostWindow: win
            }
            StatusCluster {
                onOpen: (id, item) => win.openAt(id, item)
            }
        }
    }
}
