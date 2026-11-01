import QtQuick
import "../.."

// App-grid glyph, opens the launcher popup (Bar.qml owns the PopupShell/
// LauncherMenu). Four small LEDs like WorkspacesModule's tag slots rather
// than a font glyph -- same "no font for chrome" rule as PowerButton. Idle
// they sit dim; hovering lights them in a staggered wave (Theme.staggerStep,
// same offset WorkspacesModule/SegmentBar use for their own fills) instead
// of all four snapping on together.
Item {
    id: root

    signal clicked

    implicitWidth: 16
    implicitHeight: 16

    Grid {
        anchors.fill: parent
        columns: 2
        rows: 2
        spacing: 2
        scale: hoverArea.pressed ? 0.82 : 1
        transformOrigin: Item.Center
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durFast
                easing.type: Theme.easeOut
            }
        }

        Repeater {
            model: 4

            Rectangle {
                id: led
                required property int index
                // Own plain bool, not a Theme color -- flipping it
                // imperatively from the Timer below is safe precisely
                // because nothing about it is a declarative binding target
                // itself. `color` below stays a pure expression of
                // `hoverArea.containsMouse`/`lit`, so it keeps tracking
                // Theme.segmentOff/Theme.accent (and their own palette-swap
                // crossfade) instead of getting permanently detached the
                // way an imperative `led.color = ...` assignment would.
                property bool lit: false

                width: (root.width - 2) / 2
                height: (root.height - 2) / 2
                radius: 1.5
                color: (hoverArea.containsMouse && led.lit) ? Theme.accent : Theme.segmentOff
                border.width: 1
                border.color: Theme.bevelDark

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durBase
                        easing.type: Theme.easeOut
                    }
                }

                Timer {
                    id: litDelay
                    interval: led.index * Theme.staggerStep
                    onTriggered: led.lit = true
                }

                Connections {
                    target: hoverArea
                    function onContainsMouseChanged() {
                        if (hoverArea.containsMouse) {
                            litDelay.restart();
                        } else {
                            litDelay.stop();
                            led.lit = false;
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
