import QtQuick
import "../../"

// Read-only progress bar for the system-monitor dropdown (SysMonitorDropdown.qml)
// -- same track/fill visual language as VolumeSlider.qml (4px track, radius
// 2, primary @ 0.18 track / primary fill) but without VolumeSlider's drag
// handle, since nothing here is user-adjustable.
Item {
    id: root

    property real value: 0 // 0..1
    property color fillColor: Colors.primary

    implicitHeight: 4
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 2
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.value))
            height: track.height
            radius: track.radius
            color: root.fillColor
            Behavior on width { NumberAnimation { duration: Style.anim200 } }
        }
    }
}
