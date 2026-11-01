import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    Tile {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                spacing: 18
                Layout.fillWidth: true

                ClippingRectangle {
                    id: art
                    // hop on track change
                    property string track: Media.title
                    onTrackChanged: artPop.restart()
                    SequentialAnimation {
                        id: artPop
                        NumberAnimation { target: art; property: "scale"; to: 0.86; duration: 110; easing.type: Easing.InQuad }
                        NumberAnimation { target: art; property: "scale"; to: 1; duration: 520; easing.type: Theme.easingSpring; easing.overshoot: 2.5 }
                    }
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    radius: Theme.radiusTile
                    color: Theme.tile
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: Media.art !== ""
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: Media.art === ""
                        name: "album"
                        size: 48
                        color: Theme.textDim
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    // tiny equalizer while something plays
                    Row {
                        spacing: 3
                        Layout.preferredHeight: 14
                        opacity: Media.playing ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                        Repeater {
                            model: 4
                            Rectangle {
                                id: eqBar
                                required property int index
                                anchors.bottom: parent.bottom
                                width: 3
                                radius: 1.5
                                color: Theme.accent
                                height: 3
                                SequentialAnimation on height {
                                    running: Media.playing
                                    loops: Animation.Infinite
                                    alwaysRunToEnd: true
                                    NumberAnimation { to: [12, 7, 14, 9][eqBar.index]; duration: [260, 340, 220, 300][eqBar.index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: [5, 13, 4, 11][eqBar.index]; duration: [300, 240, 330, 260][eqBar.index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 3; duration: [200, 280, 250, 220][eqBar.index]; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                    Txt { Layout.fillWidth: true; text: Media.title; font.pixelSize: 16; font.weight: Font.Bold; wrapMode: Text.Wrap; maximumLineCount: 2 }
                    Txt { Layout.fillWidth: true; text: Media.artist; color: Theme.textDim }
                    Txt { Layout.fillWidth: true; text: Media.player?.trackAlbum ?? ""; color: Theme.textFaint; font.pixelSize: Theme.fontSmall }
                }
            }

            // progress
            Slider {
                Layout.fillWidth: true
                visible: Media.player !== null && (Media.player.lengthSupported ?? false) && Media.player.length > 0
                value: Media.player ? Media.player.position / Math.max(1, Media.player.length) : 0
                enabled_: Media.player?.canSeek ?? false
                onMoved: v => { if (Media.player) Media.player.position = v * Media.player.length; }
                // position isn't pushed by MPRIS; poll while visible
                Timer {
                    interval: 1000
                    repeat: true
                    running: parent.visible && Media.playing
                    onTriggered: Media.player.positionChanged()
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                IconButton {
                    id: prevBtn
                    icon: "skip_previous"; iconSize: 22; implicitWidth: 40; implicitHeight: 40; round: true
                    onClicked: { prevKick.restart(); Media.player?.previous(); }
                    SequentialAnimation {
                        id: prevKick
                        NumberAnimation { target: prevBtn.iconItem; property: "anchors.horizontalCenterOffset"; to: -6; duration: 80 }
                        NumberAnimation { target: prevBtn.iconItem; property: "anchors.horizontalCenterOffset"; to: 0; duration: 380; easing.type: Theme.easingSpring; easing.overshoot: 3 }
                    }
                }
                IconButton {
                    id: playBtn
                    // halo breathes while playing
                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        width: parent.width; height: width; radius: width / 2
                        color: Theme.accent
                        opacity: 0
                        SequentialAnimation on scale {
                            running: Media.playing
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 1.5; duration: 1600; easing.type: Easing.OutCubic }
                        }
                        SequentialAnimation on opacity {
                            running: Media.playing
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { from: 0.35; to: 0; duration: 1600; easing.type: Easing.OutQuad }
                        }
                    }
                    icon: Media.playing ? "pause" : "play_arrow"
                    iconSize: 26
                    implicitWidth: 52
                    implicitHeight: 52
                    round: true
                    active: true
                    onClicked: Media.player?.togglePlaying()
                }
                IconButton {
                    id: nextBtn
                    icon: "skip_next"; iconSize: 22; implicitWidth: 40; implicitHeight: 40; round: true
                    onClicked: { nextKick.restart(); Media.player?.next(); }
                    SequentialAnimation {
                        id: nextKick
                        NumberAnimation { target: nextBtn.iconItem; property: "anchors.horizontalCenterOffset"; to: +6; duration: 80 }
                        NumberAnimation { target: nextBtn.iconItem; property: "anchors.horizontalCenterOffset"; to: 0; duration: 380; easing.type: Theme.easingSpring; easing.overshoot: 3 }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // player list
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: Media.players.length > 1
                Repeater {
                    model: Media.players
                    Rectangle {
                        required property var modelData
                        width: lbl.implicitWidth + 20
                        height: 26
                        radius: 13
                        color: modelData === Media.player ? Theme.accent : Theme.tile
                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                        Txt {
                            id: lbl
                            anchors.centerIn: parent
                            text: modelData.identity
                            font.pixelSize: Theme.fontSmall
                            color: modelData === Media.player ? Theme.accentInk : Theme.text
                        }
                    }
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: Media.player === null
            text: "No MPRIS player running"
            color: Theme.textDim
            z: 1
        }
    }
}
