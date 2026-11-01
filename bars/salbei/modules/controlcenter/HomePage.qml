import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    id: page
    spacing: Theme.tileGap

    property string wallpaper: ""
    property string avatar: ""

    // current wallpaper (for the banner) and ~/.face (for the avatar)
    Process {
        running: true
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1; for f in \"$HOME/.face\" \"$HOME/.face.icon\"; do [ -f \"$f\" ] && { echo \"$f\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                page.wallpaper = l[0] ?? "";
                page.avatar = l[1] ?? "";
            }
        }
    }

    // ── profile card ─────────────────────────────────────────
    ClippingRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        radius: Theme.radiusTile
        color: Theme.tile

        Image {
            id: banner
            anchors.fill: parent
            source: page.wallpaper !== "" ? "file://" + page.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 600
            asynchronous: true
            visible: false
        }
        MultiEffect {
            id: bannerFx
            anchors.fill: parent
            source: banner
            visible: banner.status === Image.Ready
            opacity: banner.status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600 } }
            // slow Ken Burns drift
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.12; duration: 14000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.12; to: 1.0; duration: 14000; easing.type: Easing.InOutSine }
            }
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.38
            saturation: -0.1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            ClippingRectangle {
                id: avatarBox
                // springs in
                scale: 0
                Component.onCompleted: scale = 1
                Behavior on scale { NumberAnimation { duration: 600; easing.type: Theme.easingSpring; easing.overshoot: 2 } }
                implicitWidth: 72
                implicitHeight: 72
                Layout.preferredWidth: 72
                Layout.maximumWidth: 72
                radius: 36
                color: Theme.accent

                Image {
                    anchors.fill: parent
                    source: page.avatar !== "" ? "file://" + page.avatar : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: page.avatar !== ""
                }
                Txt {
                    anchors.centerIn: parent
                    visible: page.avatar === ""
                    text: SystemStats.user.charAt(0).toUpperCase()
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    color: Theme.accentInk
                }
            }

            ColumnLayout {
                id: profileText
                Layout.fillWidth: true
                spacing: 2
                opacity: 0
                transform: Translate { id: profileShift; x: 16 }
                ParallelAnimation {
                    running: true
                    SequentialAnimation { PauseAnimation { duration: 120 } NumberAnimation { target: profileText; property: "opacity"; to: 1; duration: 450 } }
                    SequentialAnimation { PauseAnimation { duration: 120 } NumberAnimation { target: profileShift; property: "x"; to: 0; duration: 550; easing.type: Theme.easingEmph } }
                }
                Txt { text: SystemStats.user; font.pixelSize: Theme.fontName; font.weight: Font.Bold }
                Txt { text: SystemStats.user + "@" + SystemStats.host; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                Txt { text: "Uptime - " + SystemStats.formatUptime(SystemStats.uptime); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                Txt { text: SystemStats.shellVersion; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.tileGap

        // ── left: media over clock ───────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: Theme.tileGap

            Tile {
                order: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                interactive: Media.player !== null
                onClicked: Ui.ccPage = "media"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: "transparent"
                        border.width: 1.5
                        border.color: Media.playing ? Theme.accent : Theme.textFaint
                        Behavior on border.color { ColorAnimation { duration: Theme.animSlow } }

                        // sound ripple while playing
                        Repeater {
                            model: 2
                            Rectangle {
                                id: ripple
                                required property int index
                                anchors.centerIn: parent
                                width: 64; height: 64; radius: 32
                                color: "transparent"
                                border.width: 1.5
                                border.color: Theme.accent
                                opacity: 0
                                SequentialAnimation {
                                    running: Media.playing
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: ripple.index * 1100 }
                                    ParallelAnimation {
                                        NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.45; duration: 2200; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: ripple; property: "opacity"; from: 0.6; to: 0; duration: 2200; easing.type: Easing.OutQuad }
                                    }
                                    PauseAnimation { duration: (1 - ripple.index) * 1100 }
                                }
                            }
                        }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 54; height: 54; radius: 27
                            color: Theme.tile
                            // spins like a record while playing, holds its angle when paused
                            NumberAnimation on rotation {
                                from: 0; to: 360
                                duration: 9000
                                loops: Animation.Infinite
                                running: true
                                paused: !Media.playing
                            }
                            Image {
                                anchors.fill: parent
                                source: Media.art
                                fillMode: Image.PreserveAspectCrop
                                visible: Media.art !== ""
                                asynchronous: true
                            }
                            Icon {
                                anchors.centerIn: parent
                                visible: Media.art === ""
                                name: "album"
                                size: 26
                                color: Media.playing ? Theme.accent : Theme.textDim
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Txt { Layout.fillWidth: true; text: Media.title; font.weight: Font.DemiBold }
                        Txt { Layout.fillWidth: true; text: Media.artist; color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                    }
                }
            }

            Tile {
                order: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 84

                SystemClock { id: clock; precision: SystemClock.Minutes }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    RollingText {
                        text: Qt.formatDateTime(clock.date, WidgetSettings.clock24h ? "HH:mm" : "hh:mm AP")
                        color: Theme.accent
                        pixelSize: Theme.fontClockCard
                        weight: Font.Bold
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Txt { text: Qt.locale("en_US").toString(clock.date, "dddd"); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                        Txt { text: Qt.formatDate(clock.date, "yyyy-MM-dd"); color: Theme.textDim; font.pixelSize: Theme.fontSmall }
                    }
                }
            }
        }

        // ── right: 2×3 toggle tiles ──────────────────────────
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            columns: 2
            rowSpacing: Theme.tileGap
            columnSpacing: Theme.tileGap

            ToggleTile {
                order: 3
                icon: Network.icon
                label: Network.ssid !== "" ? Network.ssid : Network.label
                active: Network.connected
                onClicked: Network.nmRunning ? Network.setWifi(!Network.wifiEnabled) : Ui.ccPage = "network"
                onRightClicked: Ui.ccPage = "network"
            }
            ToggleTile {
                order: 4
                icon: "videocam"
                label: "Video Wallpaper"
                active: VideoWallpaper.active
                available: VideoWallpaper.available
                onClicked: VideoWallpaper.toggle()
            }
            ToggleTile {
                order: 5
                icon: Bluetooth.icon
                label: Bluetooth.available ? "Bluetooth" : "No Bluetooth"
                active: Bluetooth.enabled
                available: Bluetooth.available
                onClicked: Bluetooth.toggle()
                onRightClicked: Ui.ccPage = "bluetooth"
            }
            ToggleTile {
                order: 6
                icon: "dark_mode"
                label: "Night Light"
                active: NightLight.active
                available: NightLight.available
                onClicked: NightLight.toggle()
            }
            ToggleTile {
                order: 7
                icon: Ui.dnd ? "notifications_off" : "do_not_disturb_on"
                label: "DND"
                active: Ui.dnd
                onClicked: Ui.dnd = !Ui.dnd
            }
            ToggleTile {
                order: 8
                icon: "tune"
                label: "System"
                onClicked: Ui.ccPage = "system"
            }
        }
    }

    component ToggleTile: Tile {
        id: t
        property string icon
        property string label
        Layout.fillWidth: true
        Layout.fillHeight: true
        interactive: true

        Column {
            // icon bounces when the tile is hovered
            scale: t.hovered ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 6
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: t.icon
                size: 22
                color: t.fg
            }
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: t.label
                color: t.fg
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
