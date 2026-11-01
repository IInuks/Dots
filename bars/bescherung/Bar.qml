import QtQuick
import Quickshell
import Quickshell.Wayland

// Die Leiste: eine Reihe Geschenke oben am Bildschirm, kein Hintergrund.
// Das Fenster ist hoeher als die reservierte Zone, damit Konfetti nach
// unten fallen kann; Klicks zaehlen nur im oberen Streifen (mask).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string out: screen ? screen.name : ""

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Config.barHeight + Config.confettiRoom
    exclusiveZone: Config.barHeight
    color: "transparent"
    mask: Region {
        item: strip
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bescherung"

    Item {
        id: strip
        width: parent.width
        height: Config.barHeight
    }

    // Reihenfolge der Bescherung
    readonly property var gifts: [giftApps, giftTags, giftTitle, giftClock, giftStats, giftVolume, giftPower]

    property int _next: 0
    Timer {
        id: bescherung
        interval: Config.bescherungStagger
        repeat: true
        onTriggered: {
            if (bar._next >= bar.gifts.length) {
                stop();
                return;
            }
            bar.gifts[bar._next++].unwrap();
        }
    }
    Timer {
        id: bescherungStart
        interval: Config.bescherungDelay
        onTriggered: {
            bar._next = 0;
            bescherung.start();
        }
    }
    function startBescherung(rewrapFirst) {
        bescherung.stop();
        if (rewrapFirst)
            for (const g of gifts)
                g.wrapped = true;
        bescherungStart.restart();
    }
    Component.onCompleted: {
        if (Config.bescherungOnStart)
            startBescherung(false);
        Shots.register("bar-" + out, content);
    }
    Connections {
        target: Popups
        function onBescherungRequested() {
            bar.startBescherung(true);
        }
    }
    Timer {
        id: openSurprise
        interval: 520
        onTriggered: Popups.toggle("surprise", giftDaily, bar.screen, giftDaily.paper)
    }

    Item {
        id: content
        width: parent.width
        height: Config.barHeight + Config.confettiRoom

        Row {
            x: Config.edgeMargin
            spacing: Config.giftSpacing

            Present {
                id: giftApps
                paper: 5
                tagIcon: Theme.iGrid
                confetti: fx
                Component.onCompleted: Popups.registerAnchor(bar.out, "launcher", giftApps)
                GiftButton {
                    text: Theme.iGift
                    tint: giftApps.look.paper
                    onClicked: Popups.toggle("launcher", giftApps, bar.screen, giftApps.paper)
                }
            }
            Present {
                id: giftTags
                paper: 0
                tagIcon: Theme.iStar
                confetti: fx
                pad: 9
                Tags {
                    output: bar.out
                    accent: giftTags.look.paper
                }
            }
            Present {
                id: giftTitle
                paper: 1
                confetti: fx
                Title {
                    output: bar.out
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.giftSpacing

            Present {
                id: giftClock
                paper: 2
                confetti: fx
                pad: 14
                Clock {}
            }
            // Das Tagesgeschenk: packt sich nicht bei der Bescherung aus,
            // sondern nur einmal am Tag, wenn man es selbst oeffnet.
            Present {
                id: giftDaily
                paper: Surprises.paper
                tagIcon: Theme.iQuestion
                confetti: fx
                manual: true
                rewrappable: false
                wrapped: !Surprises.openedToday
                Component.onCompleted: Popups.registerAnchor(bar.out, "surprise", giftDaily)
                onWrappedClicked: {
                    Surprises.open();
                    openSurprise.restart();
                }
                GiftButton {
                    text: Surprises.current.icon
                    tint: giftDaily.look.paper
                    onClicked: Popups.toggle("surprise", giftDaily, bar.screen, giftDaily.paper)
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Config.edgeMargin
            spacing: Config.giftSpacing

            Present {
                id: giftStats
                paper: 3
                confetti: fx
                Stats {
                    accent: giftStats.look.paper
                }
            }
            Present {
                id: giftVolume
                paper: 4
                confetti: fx
                Volume {
                    accent: giftVolume.look.paper
                }
            }
            Present {
                id: giftPower
                paper: 6
                tagIcon: Theme.iPower
                confetti: fx
                Component.onCompleted: Popups.registerAnchor(bar.out, "power", giftPower)
                GiftButton {
                    text: Theme.iPower
                    tint: giftPower.look.paper
                    onClicked: Popups.toggle("power", giftPower, bar.screen, giftPower.paper)
                }
            }
        }

        Confetti {
            id: fx
            anchors.fill: parent
        }
    }
}
