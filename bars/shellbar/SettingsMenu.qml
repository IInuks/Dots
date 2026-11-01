import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Networking

// Settings entry point at the bar's starting corner: hover reveals a bigger
// tabbed liquid menu (Themes / Farben / Bar / Sound / WLAN) instead of just
// the old flat preset list.
LiquidMenu {
    id: settingsMenu

    menuWidth: 460
    menuContentHeight: 480

    property int activeTab: 0
    // How many Commands-tab rows currently have a pending/just-finished
    // status badge -- while > 0 the menu is pinned open, since the
    // hover-close timer (150ms) would otherwise unload the tab's content
    // (and destroy the row) before an async command's result badge is seen.
    property int activeShortcutRuns: 0
    readonly property var tabs: [
        { label: "Themes", component: themesTabComponent },
        { label: "Monitor", component: monitorTabComponent },
        { label: "Colors", component: designTabComponent },
        { label: "Bar", component: barTabComponent },
        { label: "Sound", component: soundTabComponent },
        { label: "Wi-Fi", component: wlanTabComponent },
        { label: "Commands", component: shortcutsTabComponent },
        { label: "Chess", component: chessTabComponent }
    ]

    // No visible mark: just an invisible hover zone in the bar's starting corner.
    trigger: Component {
        Item {
            implicitWidth: Settings.vertical ? Settings.barThickness : 24
            implicitHeight: Settings.vertical ? 24 : Settings.barThickness
        }
    }

    content: Component {
        ColumnLayout {
            width: parent.width
            height: parent.height
            spacing: 10

            Rectangle {
                id: tabBar
                Layout.fillWidth: true
                height: 34
                radius: 11
                color: Qt.alpha(Theme.mutedText, 0.10)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: settingsMenu.tabs

                        delegate: Rectangle {
                            id: tabButton
                            required property var modelData
                            required property int index
                            readonly property bool active: settingsMenu.activeTab === index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: active ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: tabButton.modelData.label
                                color: tabButton.active ? Theme.surface : Theme.mutedText
                                font.pixelSize: 10
                                font.bold: tabButton.active
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsMenu.activeTab = tabButton.index
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: settingsMenu.tabs[settingsMenu.activeTab].component
            }
        }
    }

    // -- Themes: pick a fixed color preset (disables the custom sliders) --
    Component {
        id: themesTabComponent
        Flickable {
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            ColumnLayout {
                id: col
                width: parent.width
                spacing: 4

                // Always-present row for whatever the Farben tab's sliders
                // currently hold, so a custom tweak stays reachable/visible
                // here instead of only existing as an implicit side effect.
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: Theme.useCustomColors ? Qt.alpha(Theme.accent, 0.15) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            radius: 3
                            color: Theme.customSurfaceOpaque
                            border.color: Qt.alpha(Theme.mutedText, 0.4)
                            border.width: 1
                        }
                        Text {
                            text: "Custom"
                            color: Theme.foreground
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.selectCustom()
                    }
                }

                Repeater {
                    model: Theme.presetOrder

                    delegate: Rectangle {
                        id: row
                        required property string modelData
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: (!Theme.useCustomColors && Theme.presetKey === modelData) ? Qt.alpha(Theme.accent, 0.15) : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: Theme.presets[row.modelData].label
                            color: Theme.foreground
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setPreset(row.modelData)
                            z: 0
                        }

                        // Explicit opt-in: copies this preset's colors into
                        // Custom without switching the sliders' base preset
                        // any other way, so Custom's own colors are only
                        // ever overwritten by pressing this.
                        Rectangle {
                            id: takeBtn
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            width: 22
                            height: 22
                            radius: 6
                            color: takeArea.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.mutedText, 0.12)
                            z: 1

                            Text {
                                anchors.centerIn: parent
                                text: "→"
                                color: Theme.foreground
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: takeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.applyPresetToCustom(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // -- Monitor: live CPU/RAM/GPU history charts + temps/disk/uptime,
    // all backed by the shared SysMonData singleton (see SysMonData.qml). --
    Component {
        id: monitorTabComponent
        Flickable {
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            ColumnLayout {
                id: col
                width: parent.width
                spacing: 12

                MonitorCard { label: "CPU"; percent: SysMonData.cpuPercent; history: SysMonData.cpuHistory }
                MonitorCard {
                    label: "RAM"
                    percent: SysMonData.ramPercent
                    history: SysMonData.ramHistory
                    valueText: SysMonData.ramTotalGB > 0
                        ? SysMonData.ramUsedGB.toFixed(1) + " / " + SysMonData.ramTotalGB.toFixed(0) + " GB"
                        : ""
                }
                MonitorCard {
                    label: SysMonData.gpuIsNvidia ? "GPU" : "GPU (AMD)"
                    percent: SysMonData.gpuPercent
                    history: SysMonData.gpuHistory
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.mutedText, 0.15); Layout.topMargin: 2 }

                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8
                    Layout.fillWidth: true

                    StatTile { label: "CPU-Temp"; value: SysMonData.cpuTemp > 0 ? Math.round(SysMonData.cpuTemp) + "°C" : "—" }
                    StatTile { label: "GPU-Temp"; value: SysMonData.gpuTemp > 0 ? Math.round(SysMonData.gpuTemp) + "°C" : "—" }
                    StatTile {
                        label: "Storage"
                        value: SysMonData.diskTotalGB > 0
                            ? SysMonData.diskUsedGB.toFixed(0) + " / " + SysMonData.diskTotalGB.toFixed(0) + " GB"
                            : "—"
                    }
                    StatTile { label: "Uptime"; value: SysMonData.uptimeText }
                }
            }
        }
    }

    // -- Farben: transparency + custom RGB sliders for surface/accent --
    Component {
        id: designTabComponent
        Flickable {
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            ColumnLayout {
                id: col
                width: parent.width
                spacing: 8

                SliderRow {
                    label: "Transparency"
                    value: Theme.useCustomColors ? Theme.customOpacity : 1.0
                    trackColor: Theme.accent
                    onMoved: v => Theme.setCustomOpacity(v)
                }

                Text { text: "Surface"; color: Theme.mutedText; font.pixelSize: 11; Layout.topMargin: 4 }
                SliderRow {
                    label: "R"
                    value: (Theme.useCustomColors ? Theme.customSurfaceR : Math.round(Qt.color(Theme.surface).r * 255)) / 255
                    trackColor: "#ff6b5c"
                    showPercent: false
                    onMoved: v => Theme.setCustomSurfaceR(Math.round(v * 255))
                }
                SliderRow {
                    label: "G"
                    value: (Theme.useCustomColors ? Theme.customSurfaceG : Math.round(Qt.color(Theme.surface).g * 255)) / 255
                    trackColor: "#5cff7a"
                    showPercent: false
                    onMoved: v => Theme.setCustomSurfaceG(Math.round(v * 255))
                }
                SliderRow {
                    label: "B"
                    value: (Theme.useCustomColors ? Theme.customSurfaceB : Math.round(Qt.color(Theme.surface).b * 255)) / 255
                    trackColor: "#5c9aff"
                    showPercent: false
                    onMoved: v => Theme.setCustomSurfaceB(Math.round(v * 255))
                }

                Text { text: "Accent"; color: Theme.mutedText; font.pixelSize: 11; Layout.topMargin: 4 }
                SliderRow {
                    label: "R"
                    value: (Theme.useCustomColors ? Theme.customAccentR : Math.round(Qt.color(Theme.accent).r * 255)) / 255
                    trackColor: "#ff6b5c"
                    showPercent: false
                    onMoved: v => Theme.setCustomAccentR(Math.round(v * 255))
                }
                SliderRow {
                    label: "G"
                    value: (Theme.useCustomColors ? Theme.customAccentG : Math.round(Qt.color(Theme.accent).g * 255)) / 255
                    trackColor: "#5cff7a"
                    showPercent: false
                    onMoved: v => Theme.setCustomAccentG(Math.round(v * 255))
                }
                SliderRow {
                    label: "B"
                    value: (Theme.useCustomColors ? Theme.customAccentB : Math.round(Qt.color(Theme.accent).b * 255)) / 255
                    trackColor: "#5c9aff"
                    showPercent: false
                    onMoved: v => Theme.setCustomAccentB(Math.round(v * 255))
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Text { text: "Light text"; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                    Toggle {
                        checked: Theme.customForegroundLight
                        onToggled: v => Theme.setCustomForegroundLight(v)
                    }
                }
            }
        }
    }

    // -- Bar: dock position + clock date toggle --
    Component {
        id: barTabComponent
        Flickable {
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            ColumnLayout {
                id: col
                width: parent.width
                spacing: 10

                Text { text: "Position"; color: Theme.mutedText; font.pixelSize: 11 }
                GridLayout {
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { key: "top", label: "Top" },
                            { key: "bottom", label: "Bottom" },
                            { key: "left", label: "Left" },
                            { key: "right", label: "Right" }
                        ]

                        delegate: Rectangle {
                            id: posButton
                            required property var modelData
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: Settings.barPosition === posButton.modelData.key ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.mutedText, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: posButton.modelData.label
                                color: Theme.foreground
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.setBarPosition(posButton.modelData.key)
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.mutedText, 0.15); Layout.topMargin: 2 }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Show date next to clock"; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                    Toggle {
                        checked: Settings.showClockDate
                        onToggled: v => Settings.setShowClockDate(v)
                    }
                }
            }
        }
    }

    // -- Sound: master volume + per-application mixer --
    Component {
        id: soundTabComponent
        Flickable {
            id: soundTab
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight

            readonly property var masterSink: Pipewire.defaultAudioSink
            readonly property bool masterReady: !!(masterSink && masterSink.ready && masterSink.audio)

            // App playback streams (things sending audio *to* a sink) --
            // excludes recording/input streams and the sinks themselves.
            readonly property var streamNodes: {
                const all = Pipewire.nodes ? Pipewire.nodes.values : [];
                return all.filter(n => n.isStream && n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream);
            }

            function appLabel(node) {
                const p = node.properties || {};
                return p["application.name"] || node.description || node.name || "?";
            }

            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 8

                SliderRow {
                    label: "Master"
                    value: soundTab.masterReady ? soundTab.masterSink.audio.volume : 0
                    trackColor: Theme.accent
                    onMoved: v => { if (soundTab.masterReady) soundTab.masterSink.audio.volume = v; }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Mute"; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                    Toggle {
                        checked: soundTab.masterReady && soundTab.masterSink.audio.muted
                        onToggled: v => { if (soundTab.masterReady) soundTab.masterSink.audio.muted = v; }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.mutedText, 0.15) }

                Repeater {
                    model: soundTab.streamNodes

                    delegate: SliderRow {
                        id: appRow
                        required property var modelData
                        label: soundTab.appLabel(appRow.modelData)
                        value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                        trackColor: Theme.accent
                        onMoved: v => { if (appRow.modelData.audio) appRow.modelData.audio.volume = v; }
                    }
                }

                Text {
                    visible: soundTab.streamNodes.length === 0
                    text: "No active programs"
                    color: Theme.mutedText
                    font.pixelSize: 11
                }
            }
        }
    }

    // -- WLAN: toggle radio, scan, connect/disconnect/forget --
    Component {
        id: wlanTabComponent
        Flickable {
            id: wlanTab
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight

            readonly property var wifiDevice: {
                const devs = Networking.devices ? Networking.devices.values : [];
                for (const d of devs) if (d.type === DeviceType.Wifi) return d;
                return null;
            }

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Wi-Fi"; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                    Toggle {
                        checked: Networking.wifiEnabled
                        onToggled: v => Networking.wifiEnabled = v
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.mutedText, 0.15) }

                Text {
                    visible: !Networking.wifiEnabled
                    text: "Wi-Fi is turned off"
                    color: Theme.mutedText
                    font.pixelSize: 11
                }

                Text {
                    visible: Networking.wifiEnabled && !wlanTab.wifiDevice
                    text: "No Wi-Fi device found"
                    color: Theme.mutedText
                    font.pixelSize: 11
                }

                Repeater {
                    model: (Networking.wifiEnabled && wlanTab.wifiDevice) ? wlanTab.wifiDevice.networks.values : []

                    delegate: ColumnLayout {
                        id: netRow
                        required property var modelData
                        readonly property var net: netRow.modelData
                        property bool expanded: false
                        Layout.fillWidth: true
                        spacing: 2

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: (netRow.expanded || netRow.net.connected) ? Qt.alpha(Theme.accent, 0.12) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    visible: netRow.net.connected
                                    color: Theme.accent
                                }
                                Text {
                                    text: netRow.net.name
                                    color: Theme.foreground
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: Math.round(netRow.net.signalStrength) + "%"
                                    color: Theme.mutedText
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (netRow.net.connected) { netRow.net.disconnect(); return; }
                                    if (netRow.net.known || netRow.net.security === WifiSecurityType.Open) { netRow.net.connect(); return; }
                                    netRow.expanded = !netRow.expanded;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: netRow.expanded
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                height: 24
                                radius: 6
                                color: Qt.alpha(Theme.mutedText, 0.12)

                                TextInput {
                                    id: pwField
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    echoMode: TextInput.Password
                                    color: Theme.foreground
                                    font.pixelSize: 11
                                    clip: true
                                    onAccepted: {
                                        netRow.net.connectWithPsk(pwField.text);
                                        netRow.expanded = false;
                                        pwField.text = "";
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 68
                                height: 24
                                radius: 6
                                color: Qt.alpha(Theme.accent, 0.25)
                                Text { anchors.centerIn: parent; text: "Connect"; color: Theme.foreground; font.pixelSize: 10 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        netRow.net.connectWithPsk(pwField.text);
                                        netRow.expanded = false;
                                        pwField.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // -- Befehle: user-defined buttons that each run one shell script.
    // "+" and the row's edit pencil both just hand values to the
    // ShortcutsEditor singleton -- the actual big centered modal lives in
    // Bar.qml's overlay (needs the whole window to center in and to grab
    // keyboard focus at the layer-shell level). --
    Component {
        id: shortcutsTabComponent
        Flickable {
            id: shortcutsTab
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 6

                Repeater {
                    model: Shortcuts.items

                    delegate: Rectangle {
                        id: shortcutRow
                        required property var modelData
                        required property int index
                        // 0 idle, 1 last run succeeded, 2 last run failed
                        property int runStatus: 0
                        // true while this row is the reason the menu is pinned open
                        property bool holdingMenuOpen: false
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: runArea.containsMouse ? Qt.alpha(Theme.accent, 0.15) : Qt.alpha(Theme.mutedText, 0.08)

                        // Safety net: if this row disappears mid-run (e.g. the user
                        // switches tabs while a command is still pending) release its
                        // hold so the menu doesn't stay pinned open forever.
                        Component.onDestruction: {
                            if (shortcutRow.holdingMenuOpen) {
                                settingsMenu.activeShortcutRuns = Math.max(0, settingsMenu.activeShortcutRuns - 1);
                                if (settingsMenu.activeShortcutRuns === 0) settingsMenu.pinned = false;
                            }
                        }

                        Timer {
                            id: statusResetTimer
                            interval: 1400
                            onTriggered: {
                                shortcutRow.runStatus = 0;
                                if (shortcutRow.holdingMenuOpen) {
                                    shortcutRow.holdingMenuOpen = false;
                                    settingsMenu.activeShortcutRuns = Math.max(0, settingsMenu.activeShortcutRuns - 1);
                                    if (settingsMenu.activeShortcutRuns === 0) settingsMenu.pinned = false;
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: shortcutRow.modelData.name
                                color: Theme.foreground
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                id: statusIcon
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: shortcutRow.runStatus === 2 ? "✕" : "✓"
                                color: shortcutRow.runStatus === 2 ? Theme.urgent : Theme.accent
                                font.pixelSize: 13
                                font.bold: true
                                opacity: shortcutRow.runStatus !== 0 ? 1 : 0
                                scale: shortcutRow.runStatus !== 0 ? 1 : 0.4

                                Behavior on opacity {
                                    NumberAnimation { duration: shortcutRow.runStatus !== 0 ? 120 : 400; easing.type: Easing.OutCubic }
                                }
                                Behavior on scale {
                                    NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 6
                                color: editArea.containsMouse ? Qt.alpha(Theme.accent, 0.25) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✎"
                                    color: Theme.mutedText
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: editArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShortcutsEditor.openForEdit(shortcutRow.index, shortcutRow.modelData.name, shortcutRow.modelData.command)
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 6
                                color: delArea.containsMouse ? Qt.alpha(Theme.urgent, 0.3) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.mutedText
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: delArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Shortcuts.removeAt(shortcutRow.index)
                                }
                            }
                        }

                        MouseArea {
                            id: runArea
                            anchors.fill: parent
                            anchors.rightMargin: 78
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                statusResetTimer.stop();
                                shortcutRow.runStatus = 0;
                                if (!shortcutRow.holdingMenuOpen) {
                                    shortcutRow.holdingMenuOpen = true;
                                    settingsMenu.activeShortcutRuns += 1;
                                    settingsMenu.pinned = true;
                                }
                                Shortcuts.run(shortcutRow.modelData.command, function (exitCode) {
                                    if (!shortcutRow) return;
                                    shortcutRow.runStatus = exitCode === 0 ? 1 : 2;
                                    statusResetTimer.restart();
                                });
                            }
                        }
                    }
                }

                Text {
                    visible: Shortcuts.items.length === 0
                    text: "No custom commands"
                    color: Theme.mutedText
                    font.pixelSize: 11
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.mutedText, 0.15); Layout.topMargin: 2; Layout.bottomMargin: 2 }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: addArea.containsMouse ? Qt.alpha(Theme.accent, 0.15) : Qt.alpha(Theme.mutedText, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.foreground
                        font.pixelSize: 15
                        font.bold: true
                    }

                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShortcutsEditor.openForAdd()
                    }
                }
            }
        }
    }

    // -- Chess: opens the big centered board (rendered in Bar.qml's
    // overlay, same reasoning as the Commands modal -- needs the whole
    // window to center in). Mode + difficulty controls live on that window
    // itself rather than duplicated here. --
    Component {
        id: chessTabComponent
        Flickable {
            width: parent.width
            height: parent.height
            clip: true
            contentHeight: col.implicitHeight
            ColumnLayout {
                id: col
                width: parent.width
                spacing: 10

                Text {
                    text: "Play chess against yourself or a bot with adjustable difficulty."
                    color: Theme.mutedText
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: playArea.containsMouse ? Qt.alpha(Theme.accent, 0.35) : Qt.alpha(Theme.accent, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "Open Chess"
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ChessState.openChess()
                    }
                }
            }
        }
    }
}
