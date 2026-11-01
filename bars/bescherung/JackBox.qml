import QtQuick
import Quickshell
import Quickshell.Wayland

// Springteufel: jedes Popup schnellt auf einer Sprungfeder aus dem
// Geschenk, aus dem es kommt, und federt nach. Schliessen zieht es wieder
// hinein. Klick neben die Karte schliesst.
PanelWindow {
    id: win

    property real cardWidth: 360
    property real cardHeight: 200
    property bool keyboard: false
    readonly property var look: Theme.paper(Popups.paper)
    default property alias body: slot.data

    readonly property real rest: 30
    property real spring: 0
    property bool closing: false
    readonly property real anchorXClamped: Math.max(30, Math.min(stage.width - 30, Popups.anchorX))

    screen: Popups.screen
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bescherung-springteufel"
    WlrLayershell.keyboardFocus: keyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function close() {
        if (closing)
            return;
        closing = true;
        shut.start();
    }

    Connections {
        target: Popups
        function onCloseRequested() {
            win.close();
        }
    }

    Behavior on spring {
        enabled: !win.closing
        SpringAnimation {
            spring: 3.4
            damping: 0.14
            epsilon: 0.05
        }
    }
    Component.onCompleted: {
        spring = rest;
        Shots.register("popup", stage);
    }

    ParallelAnimation {
        id: shut
        NumberAnimation {
            target: win
            property: "spring"
            to: 0
            duration: 230
            easing.type: Easing.InBack
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 230
            easing.type: Easing.InQuad
        }
        onFinished: Popups.close()
    }

    Item {
        id: stage
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        // Die Sprungfeder
        Canvas {
            id: coil
            x: win.anchorXClamped - width / 2
            y: -2
            width: 20
            height: Math.max(2, win.spring + 8)
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                const turns = 6, h = height - 2;
                ctx.reset();
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                for (const pass of [[4.5, Qt.darker(win.look.ribbon, 1.6)], [2.4, win.look.ribbon]]) {
                    ctx.lineWidth = pass[0];
                    ctx.strokeStyle = pass[1];
                    ctx.beginPath();
                    ctx.moveTo(width / 2, 0);
                    for (let i = 0; i <= turns * 2; i++)
                        ctx.lineTo(i % 2 ? 3 : width - 3, 2 + h * i / (turns * 2));
                    ctx.lineTo(width / 2, h + 2);
                    ctx.stroke();
                }
            }
        }

        Item {
            id: card
            width: win.cardWidth
            height: win.cardHeight
            x: Math.max(12, Math.min(stage.width - width - 12, win.anchorXClamped - width / 2))
            y: win.spring + 4
            transformOrigin: Item.Top
            scale: Math.max(0.2, Math.min(1.12, 0.25 + 0.75 * win.spring / win.rest))

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.bottomMargin: -6
                radius: 18
                color: "#33000000"
            }
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Theme.tissue
                border.width: 2
                border.color: win.look.paper
            }
            // Banderole aus demselben Papier wie das Geschenk
            WrapPaper {
                x: 10
                y: 10
                width: parent.width - 20
                height: 12
                radius: 6
                paper: Popups.paper
            }
            // Deckel, an dem die Feder haengt
            Rectangle {
                x: win.anchorXClamped - card.x - width / 2
                y: -5
                width: 34
                height: 10
                radius: 4
                color: win.look.ribbon
                border.width: 1
                border.color: Qt.darker(win.look.ribbon, 1.4)
            }

            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: slot
                anchors.fill: parent
                anchors.topMargin: 36
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.bottomMargin: 18
            }
        }
    }
}
