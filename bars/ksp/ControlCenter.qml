import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The settings flyout: four tabs -- LIVERY (accent color + bar opacity),
// COMMS (volume, shown as a KSP-style segmented resource gauge), FLIGHT
// (lock/reboot/shutdown, hold-to-confirm framed as flight actions), and
// DISPLAY (CRT scanline/vignette/flicker tuning -- the retro-look knobs).
// Tab strip pattern (Repeater driving a Loader) mirrors
// bars/chamaeleon/ControlCenter.qml; the sliding underline under the
// active tab is new here.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.controlCenterWidth
    panelHeight: Metrics.controlCenterHeight
    title: "Control Center"

    property int activeTab: 0
    readonly property var tabs: [
        { label: "Livery", component: liveryTab },
        { label: "Comms", component: commsTab },
        { label: "Flight", component: flightTab },
        { label: "Display", component: displayTab }
    ]

    Column {
        anchors.fill: parent
        spacing: 12

        Item {
            width: parent.width
            height: Metrics.tabBarHeight

            Row {
                id: tabRow
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.tabs
                    delegate: Item {
                        id: tabBtn
                        required property var modelData
                        required property int index
                        readonly property bool active: root.activeTab === tabBtn.index
                        width: tabRow.width / root.tabs.length
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            text: tabBtn.modelData.label
                            color: tabBtn.active ? Theme.text : Theme.textFaint
                            font.family: Metrics.fontFamily
                            font.pixelSize: 11
                            font.bold: tabBtn.active
                            font.letterSpacing: 1.5
                            font.capitalization: Font.AllUppercase
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = tabBtn.index
                        }
                    }
                }
            }

            Rectangle {
                width: tabRow.width / root.tabs.length
                height: 2
                color: Theme.accent
                anchors.bottom: parent.bottom
                x: (tabRow.width / root.tabs.length) * root.activeTab
                Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
                color: Qt.alpha(Theme.textFaint, 0.2)
            }
        }

        Loader {
            width: parent.width
            height: parent.height - Metrics.tabBarHeight - 12
            sourceComponent: root.tabs[root.activeTab].component
        }
    }

    // -- Livery: accent color + bar opacity + tag visibility --
    Component {
        id: liveryTab
        Column {
            width: parent.width
            spacing: 16

            Column {
                width: parent.width
                spacing: 8
                Text { text: "PAINT SCHEME"; color: Theme.textFaint; font.family: Metrics.fontMono; font.pixelSize: 10; font.letterSpacing: 1 }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: Theme.liveryOrder
                        delegate: Rectangle {
                            id: swatch
                            required property string modelData
                            readonly property bool active: Config.livery === swatch.modelData
                            width: (root.panelWidth - 24 - (Theme.liveryOrder.length - 1) * 8) / Theme.liveryOrder.length
                            height: 54
                            radius: Theme.rSmall
                            color: swatch.active ? Qt.alpha(Theme.colorFor(swatch.modelData), 0.18) : Theme.panelRaised
                            border.width: swatch.active ? 1 : 0
                            border.color: Theme.colorFor(swatch.modelData)
                            Behavior on color { ColorAnimation { duration: Theme.tFast } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 16; height: 16; radius: 8
                                    color: Theme.colorFor(swatch.modelData)
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Theme.liveryLabels[swatch.modelData] || swatch.modelData
                                    color: swatch.active ? Theme.text : Theme.textFaint
                                    font.family: Metrics.fontMono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.setLivery(swatch.modelData)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8
                Text { text: "HUD OPACITY"; color: Theme.textFaint; font.family: Metrics.fontMono; font.pixelSize: 10; font.letterSpacing: 1 }
                Row {
                    width: parent.width
                    spacing: 10
                    Slider {
                        width: parent.width - 42
                        anchors.verticalCenter: parent.verticalCenter
                        value: Config.barAlpha
                        onMoved: v => Config.setBarAlpha(v)
                    }
                    Text {
                        width: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Config.barAlpha * 100) + "%"
                        color: Theme.text
                        font.family: Metrics.fontMono
                        font.pixelSize: 11
                    }
                }
            }

            Row {
                width: parent.width
                Text {
                    text: "SHOW STAGE TAGS"
                    color: Theme.text
                    font.family: Metrics.fontFamily
                    font.pixelSize: 12
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 34; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Config.showTags ? Theme.accent : Theme.panelRaised
                    Behavior on color { ColorAnimation { duration: Theme.tMed } }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.showTags ? parent.width - width - 3 : 3
                        color: Theme.ink
                        Behavior on x { NumberAnimation { duration: Theme.tFast } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setShowTags(!Config.showTags) }
                }
            }
        }
    }

    // -- Comms: master volume as a segmented gauge + mute --
    Component {
        id: commsTab
        Item {
            id: commsRoot
            width: parent.width
            height: parent.height

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool ready: !!(sink && sink.ready && sink.audio)

            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

            Column {
                width: parent.width
                spacing: 18

                Column {
                    width: parent.width
                    spacing: 8
                    Row {
                        width: parent.width
                        Text {
                            text: "COMMS SIGNAL"
                            color: Theme.textFaint
                            font.family: Metrics.fontMono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            width: parent.width - 50
                        }
                        Text {
                            text: commsRoot.ready ? Math.round(commsRoot.sink.audio.volume * 100) + "%" : "--"
                            color: Theme.text
                            font.family: Metrics.fontMono
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    Gauge {
                        width: parent.width
                        height: 16
                        segments: 16
                        value: commsRoot.ready ? commsRoot.sink.audio.volume : 0
                    }
                    Slider {
                        width: parent.width
                        value: commsRoot.ready ? commsRoot.sink.audio.volume : 0
                        onMoved: v => { if (commsRoot.ready) commsRoot.sink.audio.volume = v; }
                    }
                }

                Row {
                    width: parent.width
                    Text {
                        text: "MUTE UPLINK"
                        color: Theme.text
                        font.family: Metrics.fontFamily
                        font.pixelSize: 12
                        width: parent.width - 40
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 34; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        color: (commsRoot.ready && commsRoot.sink.audio.muted) ? Theme.bad : Theme.panelRaised
                        Behavior on color { ColorAnimation { duration: Theme.tMed } }
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: (commsRoot.ready && commsRoot.sink.audio.muted) ? parent.width - width - 3 : 3
                            color: Theme.text
                            Behavior on x { NumberAnimation { duration: Theme.tFast } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (commsRoot.ready) commsRoot.sink.audio.muted = !commsRoot.sink.audio.muted; }
                        }
                    }
                }
            }
        }
    }

    // -- Flight: lock/reboot/shutdown, click-then-confirm within 3s --
    Component {
        id: flightTab
        Column {
            width: parent.width
            spacing: 10

            readonly property var actions: [
                { key: "lock", label: "Lock Hatch", glyph: "🔒", cmd: ["loginctl", "lock-session"] },
                { key: "reboot", label: "Reboot Craft", glyph: "⟳", cmd: ["systemctl", "reboot"] },
                { key: "shutdown", label: "End Flight", glyph: "⏻", cmd: ["systemctl", "poweroff"] }
            ]

            Repeater {
                model: parent.actions
                delegate: Rectangle {
                    id: actionRow
                    required property var modelData
                    property bool armed: false
                    width: parent.width
                    height: 44
                    radius: Theme.rSmall
                    color: actionRow.armed ? Qt.alpha(Theme.bad, 0.25) : (hoverArea.containsMouse ? Theme.panelRaised : Qt.alpha(Theme.textFaint, 0.08))
                    border.width: 1
                    border.color: actionRow.armed ? Theme.bad : Qt.alpha(Theme.textFaint, 0.15)
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }

                    SequentialAnimation on border.color {
                        running: actionRow.armed
                        loops: Animation.Infinite
                        ColorAnimation { to: Theme.bad; duration: 350 }
                        ColorAnimation { to: Qt.alpha(Theme.bad, 0.3); duration: 350 }
                    }

                    Timer {
                        id: disarmTimer
                        interval: 3000
                        onTriggered: actionRow.armed = false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.modelData.glyph
                            font.pixelSize: 15
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.armed ? "CONFIRM?" : actionRow.modelData.label.toUpperCase()
                            color: Theme.text
                            font.family: Metrics.fontFamily
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            font.bold: actionRow.armed
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (actionRow.armed) {
                                disarmTimer.stop();
                                Quickshell.execDetached(actionRow.modelData.cmd);
                                actionRow.armed = false;
                            } else {
                                actionRow.armed = true;
                                disarmTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }

    // -- Display: CRT scanline/vignette/flicker tuning --
    Component {
        id: displayTab
        Column {
            width: parent.width
            spacing: 18

            Row {
                width: parent.width
                Text {
                    text: "CRT EFFECTS"
                    color: Theme.text
                    font.family: Metrics.fontFamily
                    font.pixelSize: 12
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 34; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Config.crtEffects ? Theme.accent : Theme.panelRaised
                    Behavior on color { ColorAnimation { duration: Theme.tMed } }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.crtEffects ? parent.width - width - 3 : 3
                        color: Theme.ink
                        Behavior on x { NumberAnimation { duration: Theme.tFast } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setCrtEffects(!Config.crtEffects) }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                opacity: Config.crtEffects ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                Text { text: "SCANLINE / VIGNETTE INTENSITY"; color: Theme.textFaint; font.family: Metrics.fontMono; font.pixelSize: 10; font.letterSpacing: 1 }
                Row {
                    width: parent.width
                    spacing: 10
                    Slider {
                        width: parent.width - 42
                        anchors.verticalCenter: parent.verticalCenter
                        value: Config.crtIntensity
                        onMoved: v => Config.setCrtIntensity(v)
                    }
                    Text {
                        width: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Config.crtIntensity * 100) + "%"
                        color: Theme.text
                        font.family: Metrics.fontMono
                        font.pixelSize: 11
                    }
                }
            }

            Row {
                width: parent.width
                opacity: Config.crtEffects ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                Text {
                    text: "TUBE FLICKER"
                    color: Theme.text
                    font.family: Metrics.fontFamily
                    font.pixelSize: 12
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 34; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Config.crtFlicker ? Theme.accent : Theme.panelRaised
                    Behavior on color { ColorAnimation { duration: Theme.tMed } }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.crtFlicker ? parent.width - width - 3 : 3
                        color: Theme.ink
                        Behavior on x { NumberAnimation { duration: Theme.tFast } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setCrtFlicker(!Config.crtFlicker) }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Text { text: "PREVIEW"; color: Theme.textFaint; font.family: Metrics.fontMono; font.pixelSize: 10; font.letterSpacing: 1 }
                Rectangle {
                    width: parent.width
                    height: 46
                    radius: Theme.rSmall
                    color: Theme.panelRaised
                    clip: true
                    SevenSegmentDisplay { anchors.centerIn: parent; value: "88:88"; digitHeight: 26 }
                    CrtOverlay { anchors.fill: parent }
                }
            }
        }
    }
}
