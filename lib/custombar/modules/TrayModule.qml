import QtQuick
import Quickshell.Services.SystemTray

// System tray icons. Left click activates; right-click context menus are
// skipped for v1 -- Item.display() needs a host window handle, which the
// generic module contract (foreground/accent/settings only, see
// ZoneContent.qml) deliberately doesn't carry.
Row {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: iconDelegate
            required property var modelData
            width: 16
            height: 16

            Image {
                anchors.fill: parent
                source: iconDelegate.modelData.icon
                asynchronous: true
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: iconDelegate.modelData.activate()
            }
        }
    }
}
