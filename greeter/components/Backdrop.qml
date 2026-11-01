import QtQuick
import QtQuick.Effects
import ".."

// The wallpaper as a background, with animated blur/brightness/zoom so a
// style can react to typing. Brightness is lowered further on bright
// wallpapers (Theme.dim) to keep text readable.
Item {
    id: root

    property real blur: 0.35
    property real brightness: -0.04
    property real saturation: 0.1
    property real zoom: 1.0
    property int duration: Theme.animSlow
    // 0 = zoom follows directly (for a style that animates it continuously)
    property int zoomDuration: 1400

    readonly property bool loaded: wall.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.bg }
            GradientStop { position: 1; color: Theme.bgDeep }
        }
    }

    Image {
        id: wall
        anchors.fill: parent
        source: WallColors.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: root.loaded
        blurEnabled: root.blur > 0.001
        blurMax: 64
        blur: root.blur
        brightness: root.brightness - Theme.dim
        saturation: root.saturation
        scale: root.zoom
        opacity: root.loaded ? 1 : 0
        Behavior on blur { NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
        Behavior on brightness { NumberAnimation { duration: root.duration } }
        Behavior on saturation { NumberAnimation { duration: root.duration } }
        Behavior on scale {
            enabled: root.zoomDuration > 0
            NumberAnimation { duration: root.zoomDuration; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
    }
}
