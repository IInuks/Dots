import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"

// One window per screen (Variants in shell.qml instantiates this per
// monitor), same convention as bars/blobs/Bar.qml.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    // Local, not BarState -- there's one Bar per screen (Variants in
    // shell.qml), so a single global bool would pop the launcher open on
    // every monitor at once. LauncherState's pulses (from the mango
    // keybind) are routed to only the focused monitor's Bar below, same
    // fix as bars/fisheye/bars/blobs use for their own per-monitor popups.
    property bool launcherOpen: false

    Connections {
        target: LauncherState
        function onTogglePulse() {
            if (bar.outputName === MangoIpc.focusedMonitorName)
                bar.launcherOpen = !bar.launcherOpen;
        }
        function onOpenPulse() {
            if (bar.outputName === MangoIpc.focusedMonitorName)
                bar.launcherOpen = true;
        }
        function onClosePulse() {
            bar.launcherOpen = false;
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true

    exclusiveZone: Theme.barHeight
    implicitHeight: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "kompass-bar"
    // No popup content yet (Etappe 6-8) -- the bar never needs keyboard
    // focus at this stage. WlrKeyboardFocus.None on a layer surface blocks
    // key events to it permanently (see project memory on this), which is
    // exactly what's wanted here since nothing reads keys yet.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: panel
    }

    // Brass instrument panel, horizontally centered, width follows content.
    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 28
        height: Theme.barHeight
        radius: Theme.panelRadius
        color: Theme.panelMetal
        border.color: Theme.rivetDark
        border.width: 1

        // Riveted top edge -- four small domed pins, brass-panel signature.
        Repeater {
            model: 4
            delegate: Item {
                required property int index
                readonly property real _inset: 10
                x: index % 2 === 0 ? _inset : panel.width - _inset - width
                y: index < 2 ? _inset : panel.height - _inset - height
                width: Theme.rivetSize * 2
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.rivetDark
                }
                Rectangle {
                    width: parent.width - 1
                    height: parent.height - 1
                    x: 0
                    y: 0
                    radius: width / 2
                    color: Theme.rivetLight
                }
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10

            CompassRose {
                width: Theme.barHeight - 10
                height: width
                anchors.verticalCenter: parent.verticalCenter
                screenName: bar.outputName
            }

            Rectangle {
                width: 1
                height: Theme.barHeight - 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.dividerLine
            }

            // Placeholder readout -- Etappe 5 replaces this with a rolling
            // digit-drum (see CONCEPT.md "Zeit-Trommel"). Doubles as the
            // launcher's open/close button: growing this module's width
            // pushes the row's later children (the divider + gauge) to the
            // right, and since `panel` stays horizontally centered on
            // screen, the growth also shifts the compass rose left -- both
            // side modules visibly move out of the way, no separate
            // "push" logic needed, it falls out of the Row + centered
            // panel layout on its own.
            Item {
                id: clockModule
                width: bar.launcherOpen ? 130 : clockText.implicitWidth
                height: Theme.barHeight
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durMorph
                        easing.type: Theme.easeOutBack
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.launcherOpen = !bar.launcherOpen
                }

                Text {
                    id: clockShadow
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    anchors.verticalCenterOffset: 1
                    text: clockText.text
                    font.family: "monospace"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.panelMetalDim
                    opacity: bar.launcherOpen ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }
                }
                Text {
                    id: clockText
                    anchors.centerIn: parent
                    text: Qt.formatTime(clock.date, "hh:mm")
                    font.family: "monospace"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.panelInk
                    opacity: bar.launcherOpen ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }
                }
                SearchGlyph {
                    anchors.centerIn: parent
                    color: Theme.panelInk
                    opacity: bar.launcherOpen ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: Theme.barHeight - 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.dividerLine
            }

            Gauge {
                id: tempGauge
                width: Theme.barHeight - 10
                height: width
                anchors.verticalCenter: parent.verticalCenter
                // Scale 30-95 deg C (CONCEPT.md), zone bounds at 65/80 deg C.
                readonly property real _lo: 30
                readonly property real _hi: 95
                value: Cpu.sensorFound ? Math.max(0, Math.min(1, (Cpu.temperatureC - _lo) / (_hi - _lo))) : 0
                zones: [
                    {
                        upTo: (65 - _lo) / (_hi - _lo),
                        color: Theme.zoneGood
                    },
                    {
                        upTo: (80 - _lo) / (_hi - _lo),
                        color: Theme.zoneWarn
                    },
                    {
                        upTo: 1,
                        color: Theme.zoneCritical
                    }
                ]
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Own top-level surface, not an Item in this window -- see
    // LauncherWindow.qml's own comment for why (mango keyboard-focus
    // behavior). Loader destroys/recreates it on every open so it always
    // gets a fresh initial commit.
    Loader {
        active: bar.launcherOpen
        sourceComponent: LauncherWindow {
            modelData: bar.modelData
            onCloseRequested: bar.launcherOpen = false
        }
    }
}
